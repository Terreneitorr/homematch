from dataclasses import dataclass, field
from datetime import datetime
from typing import List, Optional
from enum import Enum

class OperationType(str, Enum):
    sale = "sale"
    rent = "rent"

class PropertyStatus(str, Enum):
    available = "available"
    reserved = "reserved"
    sold = "sold"
    rented = "rented"
    inactive = "inactive"

@dataclass
class PropertyEntity:
    id: str
    owner_id: str
    title: str
    description: str
    price: float
    operation_type: OperationType
    city: str
    zone: str
    area: float
    status: PropertyStatus = PropertyStatus.available
    colony: Optional[str] = None
    bedrooms: int = 1
    bathrooms: int = 1
    has_garage: bool = False
    has_garden: bool = False
    photos: List[str] = field(default_factory=list)
    cluster: Optional[int] = None
    created_at: Optional[datetime] = None
