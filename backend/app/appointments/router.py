from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import Column, String, DateTime, Enum as SAEnum
from app.database import Base, get_db
from app.models import User
from app.auth.dependencies import get_current_user
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import uuid
import enum

class AppointmentType(str, enum.Enum):
    presencial = "presencial"
    virtual = "virtual"
    telefonica = "telefonica"

class AppointmentStatus(str, enum.Enum):
    pendiente = "pendiente"
    confirmada = "confirmada"
    cancelada = "cancelada"
    reagendada = "reagendada"

class Appointment(Base):
    __tablename__ = "appointments"
    id = Column(String, primary_key=True)
    user_id = Column(String, nullable=False)
    seller_id = Column(String, nullable=False)
    property_id = Column(String, nullable=False)
    appointment_type = Column(SAEnum(AppointmentType), default=AppointmentType.presencial)
    status = Column(SAEnum(AppointmentStatus), default=AppointmentStatus.pendiente)
    scheduled_at = Column(DateTime, nullable=False)
    notes = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

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
    return appointment

@router.put("/{appointment_id}/status")
def update_status(
        appointment_id: str,
        status: str,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    apt = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if not apt:
        raise HTTPException(status_code=404, detail="Cita no encontrada")
    apt.status = status
    db.commit()
    return {"message": "Estado actualizado"}

@router.delete("/{appointment_id}")
def cancel_appointment(
        appointment_id: str,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    apt = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if not apt:
        raise HTTPException(status_code=404, detail="No encontrada")
    apt.status = AppointmentStatus.cancelada
    db.commit()
    return {"message": "Cita cancelada"}