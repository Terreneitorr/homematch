import stripe
import os
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from app.infrastructure.database.database import get_db
from app.infrastructure.database.models import User
from app.infrastructure.security.dependencies import get_current_user
from pydantic import BaseModel
from typing import Optional
import uuid
from datetime import datetime

stripe.api_key = os.getenv("STRIPE_SECRET_KEY", "sk_test_YOUR_KEY")

PLANS = {
    "premium_user": {
        "name": "HomeMatch Premium",
        "price": 9900,  # $99 MXN en centavos
        "currency": "mxn",
        "description": "Acceso premium para compradores",
    },
    "agency": {
        "name": "HomeMatch Inmobiliaria",
        "price": 49900,  # $499 MXN
        "currency": "mxn",
        "description": "Plan para inmobiliarias",
    },
}

class PaymentIntentRequest(BaseModel):
    plan: str
    currency: str = "mxn"

class PaymentIntentResponse(BaseModel):
    client_secret: str
    amount: int
    currency: str
    plan: str

router = APIRouter()

@router.post("/create-payment-intent", response_model=PaymentIntentResponse)
async def create_payment_intent(
        data: PaymentIntentRequest,
        current_user: User = Depends(get_current_user)
):
    plan = PLANS.get(data.plan)
    if not plan:
        raise HTTPException(status_code=400, detail="Plan no válido")

    try:
        intent = stripe.PaymentIntent.create(
            amount=plan["price"],
            currency=plan["currency"],
            metadata={
                "user_id": current_user.id,
                "user_email": current_user.email,
                "plan": data.plan,
            },
            description=plan["description"],
        )
        return PaymentIntentResponse(
            client_secret=intent.client_secret,
            amount=plan["price"],
            currency=plan["currency"],
            plan=data.plan,
        )
    except stripe.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/plans")
async def get_plans():
    return [
        {
            "id": key,
            "name": plan["name"],
            "price": plan["price"] / 100,
            "currency": plan["currency"].upper(),
            "description": plan["description"],
        }
        for key, plan in PLANS.items()
    ]

@router.post("/webhook")
async def stripe_webhook(request: Request, db: Session = Depends(get_db)):
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature")
    webhook_secret = os.getenv("STRIPE_WEBHOOK_SECRET", "")

    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, webhook_secret
        )
    except ValueError:
        raise HTTPException(status_code=400, detail="Payload inválido")
    except stripe.SignatureVerificationError:
        raise HTTPException(status_code=400, detail="Firma inválida")

    if event["type"] == "payment_intent.succeeded":
        intent = event["data"]["object"]
        user_id = intent["metadata"].get("user_id")
        plan = intent["metadata"].get("plan")

        # Actualizar rol del usuario según el plan
        if user_id and plan:
            user = db.query(User).filter(User.id == user_id).first()
            if user:
                from app.infrastructure.database.models import UserRole
                if plan == "agency":
                    user.role = UserRole.AGENCY
                db.commit()

    return {"status": "ok"}