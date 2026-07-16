from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.infrastructure.database.database import get_db
from app.infrastructure.database.models import User, Appointment
from app.infrastructure.security.dependencies import get_current_user
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import uuid
from app.fcm.router import notify_appointment

class AppointmentCreate(BaseModel):
    property_id: str
    seller_id: str
    appointment_type: str = "presencial"
    scheduled_at: datetime
    notes: Optional[str] = None

class AppointmentResponse(BaseModel):
    id: str
    user_id: str
    seller_id: str
    property_id: str
    appointment_type: str
    status: str
    scheduled_at: datetime
    notes: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

router = APIRouter()

@router.get("/", response_model=List[AppointmentResponse])
def get_appointments(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return db.query(Appointment).filter(
        (Appointment.user_id == current_user.id) |
        (Appointment.seller_id == current_user.id)
    ).order_by(Appointment.scheduled_at).all()

@router.post("/", response_model=AppointmentResponse)
def create_appointment(
    data: AppointmentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    appointment = Appointment(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        seller_id=data.seller_id,
        property_id=data.property_id,
        appointment_type=data.appointment_type,
        scheduled_at=data.scheduled_at,
        notes=data.notes,
    )
    db.add(appointment)
    db.commit()
    db.refresh(appointment)

    # Push notifications reales
    notify_appointment(
        db=db,
        user_id=current_user.id,
        seller_id=data.seller_id,
        appointment_type=data.appointment_type,
        scheduled_at=str(data.scheduled_at),
    )

    return appointment

@router.delete("/{appointment_id}")
def cancel_appointment(
    appointment_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    apt = db.query(Appointment).filter(
        Appointment.id == appointment_id
    ).first()
    if not apt:
        raise HTTPException(status_code=404, detail="No encontrada")
    
    # role es String
    if current_user.id != apt.user_id and current_user.id != apt.seller_id and current_user.role != "ADMIN":
        raise HTTPException(status_code=403, detail="Sin permiso")

    apt.status = "cancelada"
    db.commit()
    return {"message": "Cita cancelada"}
