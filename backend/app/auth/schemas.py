from pydantic import BaseModel, EmailStr
from typing import Optional


class RegisterRequest(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: str = "USER"


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class GoogleLoginRequest(BaseModel):
    google_id: str
    name: str
    email: EmailStr
    avatar: Optional[str] = None
    role: str = "USER"


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    user_id: str
    name: str
    email: EmailStr
    accepted_terms: bool = False
    is_new_user: bool = False
    avatar: Optional[str] = None
    subscription_plan: Optional[str] = None
    subscription_status: Optional[str] = None