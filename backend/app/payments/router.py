import stripe
import os
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User, UserRole
from app.auth.dependencies import get_current_user
from pydantic import BaseModel

stripe.api_key = os.getenv("STRIPE_SECRET_KEY", "")

# price_id sacados del Dashboard de Stripe (modo test)
PLANS = {
    "premium_user": {
        "price_id": "price_1Tv9gJAnoJRpC7akS0kX44wp",
        "name": "HomeMatch Premium",
        "amount": 9900,
        "currency": "mxn",
        "description": "Acceso premium para compradores",
    },
    "agency": {
        "price_id": "price_1Tv9i6AnoJRpC7akefxEI0ge",
        "name": "HomeMatch Inmobiliaria",
        "amount": 49900,
        "currency": "mxn",
        "description": "Plan para inmobiliarias",
    },
}

router = APIRouter()


class SubscriptionRequest(BaseModel):
    plan: str


class SubscriptionResponse(BaseModel):
    client_secret: str
    subscription_id: str
    amount: int
    currency: str
    plan: str


class SubscriptionStatusResponse(BaseModel):
    plan: str | None
    status: str | None


def _get_or_create_customer(user: User, db: Session) -> str:
    """Reutiliza el Customer de Stripe del usuario si ya existe, si no lo crea."""
    if user.stripe_customer_id:
        return user.stripe_customer_id

    customer = stripe.Customer.create(
        email=user.email,
        name=user.name,
        metadata={"user_id": user.id},
    )
    user.stripe_customer_id = customer.id
    db.commit()
    return customer.id


@router.get("/plans")
async def get_plans():
    return [
        {
            "id": key,
            "name": plan["name"],
            "price": plan["amount"] / 100,
            "currency": plan["currency"].upper(),
            "description": plan["description"],
        }
        for key, plan in PLANS.items()
    ]


@router.get("/my-subscription", response_model=SubscriptionStatusResponse)
async def my_subscription(current_user: User = Depends(get_current_user)):
    """Para que la app sepa qué plan/estatus tiene el usuario y refresque su UI."""
    return SubscriptionStatusResponse(
        plan=current_user.subscription_plan,
        status=current_user.subscription_status,
    )


@router.post("/create-subscription", response_model=SubscriptionResponse)
async def create_subscription(
        data: SubscriptionRequest,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user),
):
    plan = PLANS.get(data.plan)
    if not plan:
        raise HTTPException(status_code=400, detail="Plan no válido")

    if current_user.subscription_status == "active" and current_user.subscription_plan == data.plan:
        raise HTTPException(status_code=400, detail="Ya tienes este plan activo")

    try:
        customer_id = _get_or_create_customer(current_user, db)

        subscription = stripe.Subscription.create(
            customer=customer_id,
            items=[{"price": plan["price_id"]}],
            payment_behavior="default_incomplete",
            payment_settings={"save_default_payment_method": "on_subscription"},
            expand=["latest_invoice.payment_intent"],
            metadata={"user_id": current_user.id, "plan": data.plan},
        )

        current_user.stripe_subscription_id = subscription.id
        current_user.subscription_plan = data.plan
        current_user.subscription_status = subscription.status  # normalmente "incomplete" hasta que se confirme el pago
        db.commit()

        client_secret = subscription.latest_invoice.payment_intent.client_secret

        return SubscriptionResponse(
            client_secret=client_secret,
            subscription_id=subscription.id,
            amount=plan["amount"],
            currency=plan["currency"],
            plan=data.plan,
        )
    except stripe.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/cancel-subscription")
async def cancel_subscription(
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user),
):
    if not current_user.stripe_subscription_id:
        raise HTTPException(status_code=400, detail="No tienes una suscripción activa")

    try:
        # Se cancela al final del periodo ya pagado, no de inmediato
        stripe.Subscription.modify(
            current_user.stripe_subscription_id,
            cancel_at_period_end=True,
        )
        return {"message": "La suscripción se cancelará al final del periodo actual"}
    except stripe.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/webhook")
async def stripe_webhook(request: Request, db: Session = Depends(get_db)):
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature")
    webhook_secret = os.getenv("STRIPE_WEBHOOK_SECRET", "")

    try:
        event = stripe.Webhook.construct_event(payload, sig_header, webhook_secret)
    except ValueError:
        raise HTTPException(status_code=400, detail="Payload inválido")
    except stripe.SignatureVerificationError:
        raise HTTPException(status_code=400, detail="Firma inválida")

    event_type = event["type"]
    data_object = event["data"]["object"]

    if event_type == "invoice.payment_succeeded":
        subscription_id = data_object.get("subscription")
        if subscription_id:
            user = db.query(User).filter(User.stripe_subscription_id == subscription_id).first()
            if user:
                user.subscription_status = "active"
                if user.subscription_plan == "agency":
                    user.role = UserRole.AGENCY
                db.commit()

    elif event_type == "customer.subscription.updated":
        subscription_id = data_object.get("id")
        new_status = data_object.get("status")
        user = db.query(User).filter(User.stripe_subscription_id == subscription_id).first()
        if user and new_status:
            user.subscription_status = new_status
            db.commit()

    elif event_type == "customer.subscription.deleted":
        subscription_id = data_object.get("id")
        user = db.query(User).filter(User.stripe_subscription_id == subscription_id).first()
        if user:
            user.subscription_status = "canceled"
            user.subscription_plan = None
            # Nota: no revertimos user.role automáticamente aquí (de AGENCY a USER)
            # para no romper datos/propiedades que la agencia ya haya publicado.
            # Si se requiere ese comportamiento, es una decisión de negocio a definir.
            db.commit()

    return {"status": "ok"}