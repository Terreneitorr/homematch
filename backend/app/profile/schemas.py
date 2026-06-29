from pydantic import BaseModel
from typing import Optional

class ProfileUpdate(BaseModel):
    name: Optional[str] = None
    avatar: Optional[str] = None

class ProfileResponse(BaseModel):
    id: str
    name: str
    email: str
    role: str
    avatar: Optional[str]
    is_active: bool

    class Config:
        from_attributes = True