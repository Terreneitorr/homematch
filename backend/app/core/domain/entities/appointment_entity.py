from dataclasses import dataclass
from datetime import datetime
from typing import Optional

@dataclass
class AppointmentEntity:
    id: str
    user_id: str
    seller_id: str
    property_id: str
    scheduled_at: datetime
    appointment_type: str = "presencial"
    status: str = "pendiente"
    notes: Optional[str] = None
    created_at: Optional[datetime] = None
