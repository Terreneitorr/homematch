from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.infrastructure.database.database import get_db
from app.infrastructure.database.models import User, SellerSchedule
from app.infrastructure.security.dependencies import get_current_user
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime, date, timedelta
import uuid

class ScheduleUpdate(BaseModel):
    monday: bool = True
    tuesday: bool = True
    wednesday: bool = True
    thursday: bool = True
    friday: bool = True
    saturday: bool = False
    sunday: bool = False
    start_hour: int = 9
    end_hour: int = 18
    slot_duration: int = 60

class ScheduleResponse(BaseModel):
    id: str
    seller_id: str
    monday: bool
    tuesday: bool
    wednesday: bool
    thursday: bool
    friday: bool
    saturday: bool
    sunday: bool
    start_hour: int
    end_hour: int
    slot_duration: int

    class Config:
        from_attributes = True

class TimeSlot(BaseModel):
    datetime: str
    available: bool

router = APIRouter()

@router.get("/me", response_model=ScheduleResponse)
def get_my_schedule(
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    schedule = db.query(SellerSchedule).filter(
        SellerSchedule.seller_id == current_user.id
    ).first()
    if not schedule:
        schedule = SellerSchedule(
            id=str(uuid.uuid4()),
            seller_id=current_user.id,
        )
        db.add(schedule)
        db.commit()
        db.refresh(schedule)
    return schedule

@router.put("/me", response_model=ScheduleResponse)
def update_schedule(
        data: ScheduleUpdate,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    schedule = db.query(SellerSchedule).filter(
        SellerSchedule.seller_id == current_user.id
    ).first()
    if not schedule:
        schedule = SellerSchedule(
            id=str(uuid.uuid4()),
            seller_id=current_user.id,
        )
        db.add(schedule)

    for field, value in data.model_dump().items():
        setattr(schedule, field, value)

    db.commit()
    db.refresh(schedule)
    return schedule

@router.get("/{seller_id}/slots")
def get_available_slots(
        seller_id: str,
        date_str: str,
        db: Session = Depends(get_db)
):
    schedule = db.query(SellerSchedule).filter(
        SellerSchedule.seller_id == seller_id
    ).first()

    if not schedule:
        return {"slots": [], "message": "Vendedor sin horario configurado"}

    try:
        target_date = datetime.strptime(date_str, "%Y-%m-%d").date()
    except ValueError:
        raise HTTPException(status_code=400, detail="Formato de fecha inválido")

    day_map = {
        0: schedule.monday,
        1: schedule.tuesday,
        2: schedule.wednesday,
        3: schedule.thursday,
        4: schedule.friday,
        5: schedule.saturday,
        6: schedule.sunday,
    }

    weekday = target_date.weekday()
    if not day_map.get(weekday, False):
        return {"slots": [], "message": "El vendedor no atiende este día"}

    slots = []
    current_hour = schedule.start_hour
    while current_hour < schedule.end_hour:
        slot_time = datetime.combine(
            target_date,
            datetime.min.time().replace(hour=current_hour)
        )
        slots.append({
            "time": f"{current_hour:02d}:00",
            "datetime": slot_time.isoformat(),
            "available": True,
        })
        current_hour += (schedule.slot_duration // 60)

    return {"slots": slots, "date": date_str}