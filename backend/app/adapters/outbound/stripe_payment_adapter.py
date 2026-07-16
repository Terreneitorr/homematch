import stripe
import os
from typing import Optional
from app.core.domain.ports.payment_port import (
    PaymentPort, PaymentIntent, PaymentResult
)

stripe.api_key = os.getenv("STRIPE_SECRET_KEY", "")
WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET", "")


class StripePaymentAdapter(PaymentPort):

    async def create_payment_intent(
            self,
            amount: int,
            currency: str,
            user_id: str,
            plan: str,
            description: str,
    ) -> PaymentIntent:
        intent = stripe.PaymentIntent.create(
            amount=amount,
            currency=currency,
            metadata={
                "user_id": user_id,
                "plan": plan,
            },
            description=description,
        )
        return PaymentIntent(
            client_secret=intent.client_secret,
            amount=amount,
            currency=currency,
            payment_id=intent.id,
        )

    async def verify_webhook(
            self,
            payload: bytes,
            signature: str,
    ) -> Optional[PaymentResult]:
        try:
            event = stripe.Webhook.construct_event(
                payload, signature, WEBHOOK_SECRET
            )
        except Exception:
            return None

        if event["type"] == "payment_intent.succeeded":
            intent = event["data"]["object"]
            return PaymentResult(
                success=True,
                payment_id=intent["id"],
                user_id=intent["metadata"].get("user_id", ""),
                plan=intent["metadata"].get("plan", ""),
                amount=intent["amount"],
            )
        return None