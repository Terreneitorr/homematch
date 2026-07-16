from app.core.domain.ports.payment_port import PaymentPort, PaymentIntent


PLANS = {
    "premium_user": {
        "name": "HomeMatch Premium",
        "amount": 9900,
        "currency": "mxn",
        "description": "Acceso premium para compradores",
    },
    "agency": {
        "name": "HomeMatch Inmobiliaria",
        "amount": 49900,
        "currency": "mxn",
        "description": "Plan para inmobiliarias",
    },
}


class CreatePaymentIntentUseCase:
    def __init__(self, payment_port: PaymentPort):
        self._payment = payment_port

    async def execute(
            self,
            plan_id: str,
            user_id: str,
    ) -> PaymentIntent:
        plan = PLANS.get(plan_id)
        if not plan:
            raise ValueError(f"Plan no válido: {plan_id}")

        return await self._payment.create_payment_intent(
            amount=plan["amount"],
            currency=plan["currency"],
            user_id=user_id,
            plan=plan_id,
            description=plan["description"],
        )