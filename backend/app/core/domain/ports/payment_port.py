from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Optional


@dataclass
class PaymentIntent:
    client_secret: str
    amount: int
    currency: str
    payment_id: str


@dataclass
class PaymentResult:
    success: bool
    payment_id: str
    user_id: str
    plan: str
    amount: int


class PaymentPort(ABC):

    @abstractmethod
    async def create_payment_intent(
            self,
            amount: int,
            currency: str,
            user_id: str,
            plan: str,
            description: str,
    ) -> PaymentIntent:
        pass

    @abstractmethod
    async def verify_webhook(
            self,
            payload: bytes,
            signature: str,
    ) -> Optional[PaymentResult]:
        pass