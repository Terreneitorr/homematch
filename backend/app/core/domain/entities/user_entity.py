from dataclasses import dataclass
from datetime import datetime
from typing import Optional
from enum import Enum

class UserRole(str, Enum):
    USER = "USER"
    SELLER = "SELLER"
    AGENCY = "AGENCY"
    ADMIN = "ADMIN"

@dataclass
class UserEntity:
    id: str
    name: str
    email: str
    role: UserRole
    password_hash: Optional[str] = None
    avatar: Optional[str] = None
    is_active: bool = True
    accepted_terms: bool = False
    created_at: Optional[datetime] = None

    def can_publish(self) -> bool:
        return self.role in [UserRole.SELLER, UserRole.AGENCY, UserRole.ADMIN]

    def is_admin(self) -> bool:
        return self.role == UserRole.ADMIN
