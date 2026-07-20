from pydantic import BaseModel
from typing import Optional


class RegisterRequest(BaseModel):
    name: str
    email: str
    password: str
    role: str = "USER"


class LoginRequest(BaseModel):
    email: str
    password: str


class GoogleLoginRequest(BaseModel):
    google_id: str
    name: str
    email: str
    avatar: Optional[str] = None
    role: str = "USER"


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    user_id: str
    name: str
    email: str
    accepted_terms: bool = False
    is_new_user: bool = False
    avatar: Optional[str] = None
    subscription_plan: Optional[str] = None
    subscription_status: Optional[str] = None