from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.infrastructure.database.database import get_db
from app.infrastructure.database.models import User
from app.infrastructure.security.dependencies import get_current_user
from app.profile.schemas import ProfileUpdate, ProfileResponse

router = APIRouter()

@router.get("/", response_model=ProfileResponse)
def get_profile(current_user: User = Depends(get_current_user)):
    return current_user

@router.put("/", response_model=ProfileResponse)
def update_profile(
        data: ProfileUpdate,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    for field, value in data.model_dump(exclude_none=True).items():
        setattr(current_user, field, value)
    db.commit()
    db.refresh(current_user)
    return current_user