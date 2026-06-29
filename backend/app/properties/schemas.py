from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class PropertyCreate(BaseModel):
    title: str
    description: str
    price: float
    operation_type: str
    city: str
    zone: str
    colony: Optional[str] = None
    bedrooms: int = 1
    bathrooms: int = 1
    has_garage: bool = False
    has_garden: bool = False
    area: float

class PropertyUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    status: Optional[str] = None
    city: Optional[str] = None
    zone: Optional[str] = None
    bedrooms: Optional[int] = None
    bathrooms: Optional[int] = None
    has_garage: Optional[bool] = None
    has_garden: Optional[bool] = None
    area: Optional[float] = None

class PropertyResponse(BaseModel):
    id: str
    owner_id: str
    title: str
    description: str
    price: float
    operation_type: str
    status: str
    city: str
    zone: str
    colony: Optional[str]
    bedrooms: int
    bathrooms: int
    has_garage: bool
    has_garden: bool
    area: float
    photos: str
    cluster: Optional[int]
    created_at: datetime

    class Config:
        from_attributes = True