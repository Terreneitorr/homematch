from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.infrastructure.database.database import get_db
from app.infrastructure.database.models import User, Notification, UserRole
from app.infrastructure.security.dependencies import get_current_user
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import uuid

class NotificationResponse(BaseModel):
    id: str
    user_id: str
    title: str
    body: str
    type: str
    is_read: bool
    data: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

class NotificationCreate(BaseModel):
    user_id: str
    title: str
    body: str
    type: str = "general"
    data: Optional[str] = None

router = APIRouter()

@router.get("/", response_model=List[NotificationResponse])
def get_notifications(
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    return db.query(Notification).filter(
        Notification.user_id == current_user.id
    ).order_by(Notification.created_at.desc()).limit(50).all()

@router.put("/{notification_id}/read")
def mark_read(
        notification_id: str,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    notif = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id
    ).first()
    if not notif:
        raise HTTPException(status_code=404, detail="No encontrada")
    notif.is_read = True
    db.commit()
    return {"message": "Marcada como leída"}

@router.put("/read-all")
def mark_all_read(
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    db.query(Notification).filter(
        Notification.user_id == current_user.id,
        Notification.is_read == False
    ).update({"is_read": True})
    db.commit()
    return {"message": "Todas marcadas como leídas"}

@router.get("/unread-count")
def unread_count(
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    count = db.query(Notification).filter(
        Notification.user_id == current_user.id,
        Notification.is_read == False
    ).count()
    return {"count": count}

@router.delete("/{notification_id}")
def delete_notification(
        notification_id: str,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    """Borra UNA notificación del usuario actual."""
    notif = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id
    ).first()
    if not notif:
        raise HTTPException(status_code=404, detail="No encontrada")
    db.delete(notif)
    db.commit()
    return {"message": "Notificación eliminada"}

@router.delete("/")
def clear_notifications(
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    """Borra TODAS las notificaciones del usuario actual."""
    db.query(Notification).filter(
        Notification.user_id == current_user.id
    ).delete()
    db.commit()
    return {"message": "Notificaciones eliminadas"}

@router.post("/internal", response_model=NotificationResponse)
def create_notification(
        data: NotificationCreate,
        db: Session = Depends(get_db),
):
    notif = Notification(
        id=str(uuid.uuid4()),
        user_id=data.user_id,
        title=data.title,
        body=data.body,
        type=data.type,
        data=data.data,
    )
    db.add(notif)
    db.commit()
    db.refresh(notif)
    return notif


def notify_new_property(db: Session, property_title: str, property_id: str, exclude_owner_id: str):
    """
    Crea una notificación en la BD para todos los compradores (rol USER)
    activos cuando se publica una propiedad nueva, excluyendo al dueño que
    la acaba de publicar. Se llama desde properties/router.py al crear una
    propiedad.

    NOTA: esto solo crea el registro que se ve en la pantalla de
    notificaciones dentro de la app (NotificationsView). Para que también
    llegue como notificación push (con la app cerrada), hay que enviarla
    también por FCM — eso requiere el servicio de FCM que ya tienes, pero
    no se integró aquí porque no se revisó ese archivo en esta sesión.
    """
    buyers = db.query(User).filter(
        User.role == UserRole.USER,
        User.is_active == True,
        User.id != exclude_owner_id,
        ).all()

    for buyer in buyers:
        notif = Notification(
            id=str(uuid.uuid4()),
            user_id=buyer.id,
            title="Nueva propiedad publicada",
            body=f'Se publicó "{property_title}", ¡échale un vistazo!',
            type="property",
            data=property_id,
        )
        db.add(notif)
    db.commit()