from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User, Appointment, AppointmentStatus
from app.auth.dependencies import get_current_user
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import uuid

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
    apt.status = AppointmentStatus.cancelada
    db.commit()
    return {"message": "Cita cancelada"}

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

    # Seguridad: solo dueño o cliente
    if current_user.id != apt.seller_id and current_user.id != apt.user_id:
        raise HTTPException(status_code=403, detail="Sin permiso")

    # Mapeo manual para evitar errores de Enum
    status_map = {
        "confirmada": AppointmentStatus.confirmada,
        "rechazada": AppointmentStatus.rechazada,
        "cancelada": AppointmentStatus.cancelada,
        "reagendada": AppointmentStatus.reagendada,
        "pendiente": AppointmentStatus.pendiente,
    }

    new_status = status_map.get(status.lower())
    if not new_status:
        raise HTTPException(status_code=400, detail=f"Estado '{status}' no es válido")

    apt.status = new_status
    db.commit()
    return {"message": "Estado actualizado", "new_status": apt.status}
