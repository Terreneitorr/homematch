from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import Column, String, Boolean, DateTime, Text
from app.database import Base, get_db
from app.models import User
from app.auth.dependencies import get_current_user
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import uuid

class Notification(Base):
    __tablename__ = "notifications"
    id = Column(String, primary_key=True)
    user_id = Column(String, nullable=False)
    title = Column(String, nullable=False)
    body = Column(Text, nullable=False)
    type = Column(String, default="general")
    is_read = Column(Boolean, default=False)
    data = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

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