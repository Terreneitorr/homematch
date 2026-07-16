from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.infrastructure.database.database import get_db
from app.infrastructure.database.models import User, FCMToken
from app.infrastructure.security.dependencies import get_current_user
from app.infrastructure.fcm_service import FCMService
from pydantic import BaseModel
from typing import Optional
import uuid

class FCMTokenRegister(BaseModel):
    token: str
    device: Optional[str] = "android"

class WipeRequest(BaseModel):
    user_id: str

router = APIRouter()

@router.post("/register-token")
def register_token(
        data: FCMTokenRegister,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    # Eliminar tokens anteriores del usuario
    db.query(FCMToken).filter(
        FCMToken.user_id == current_user.id
    ).delete()

    token = FCMToken(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        token=data.token,
        device=data.device,
    )
    db.add(token)
    db.commit()
    return {"message": "Token registrado"}

@router.post("/send-wipe")
def send_remote_wipe(
        data: WipeRequest,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    # role es un String en el modelo
    if current_user.role != "ADMIN":
        raise HTTPException(status_code=403, detail="Sin permiso")

    tokens = db.query(FCMToken).filter(
        FCMToken.user_id == data.user_id
    ).all()

    if not tokens:
        raise HTTPException(
            status_code=404,
            detail="No hay dispositivos registrados para este usuario"
        )

    sent = 0
    for fcm_token in tokens:
        if FCMService.send_remote_wipe(fcm_token.token, data.user_id):
            sent += 1

    return {"message": f"Wipe enviado a {sent} dispositivos"}


def notify_appointment(
        db: Session,
        user_id: str,
        seller_id: str,
        appointment_type: str,
        scheduled_at: str,
):
    """Función helper para notificar sobre citas"""
    # Notificar al comprador
    buyer_tokens = db.query(FCMToken).filter(
        FCMToken.user_id == user_id
    ).all()
    for t in buyer_tokens:
        FCMService.send_appointment_notification(
            token=t.token,
            appointment_type=appointment_type,
            scheduled_at=scheduled_at,
            is_seller=False,
        )

    # Notificar al vendedor
    seller_tokens = db.query(FCMToken).filter(
        FCMToken.user_id == seller_id
    ).all()
    for t in seller_tokens:
        FCMService.send_appointment_notification(
            token=t.token,
            appointment_type=appointment_type,
            scheduled_at=scheduled_at,
            is_seller=True,
        )


def notify_message(
        db: Session,
        receiver_id: str,
        sender_name: str,
        message_content: str,
        conversation_id: str,
):
    """Función helper para notificar mensajes"""
    tokens = db.query(FCMToken).filter(
        FCMToken.user_id == receiver_id
    ).all()
    for t in tokens:
        FCMService.send_new_message_notification(
            token=t.token,
            sender_name=sender_name,
            message_preview=message_content,
            conversation_id=conversation_id,
        )
