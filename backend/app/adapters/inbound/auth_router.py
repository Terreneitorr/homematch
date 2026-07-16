from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.infrastructure.database.database import get_db
from app.adapters.outbound.postgres_user_repository import PostgresUserRepository
from app.core.use_cases.auth.register_use_case import RegisterUseCase
from app.core.use_cases.auth.login_use_case import LoginUseCase
from app.core.use_cases.auth.google_login_use_case import GoogleLoginUseCase
from app.adapters.inbound.auth_schemas import RegisterRequest, LoginRequest, GoogleLoginRequest, TokenResponse
from app.infrastructure.security.dependencies import get_current_user
from app.infrastructure.database.models import User
from app.infrastructure.security.utils import create_access_token

router = APIRouter()

@router.post("/register", response_model=TokenResponse)
async def register(data: RegisterRequest, db: Session = Depends(get_db)):
    user_repo = PostgresUserRepository(db)
    use_case = RegisterUseCase(user_repo)
    try:
        return await use_case.execute(data.name, data.email, data.password, data.role)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/login", response_model=TokenResponse)
async def login(data: LoginRequest, db: Session = Depends(get_db)):
    user_repo = PostgresUserRepository(db)
    use_case = LoginUseCase(user_repo)
    try:
        return await use_case.execute(data.email, data.password)
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))

@router.post("/google", response_model=TokenResponse)
async def google_login(data: GoogleLoginRequest, db: Session = Depends(get_db)):
    user_repo = PostgresUserRepository(db)
    use_case = GoogleLoginUseCase(user_repo)
    return await use_case.execute(data.google_id, data.name, data.email, data.avatar, data.role)

@router.post("/accept-terms")
def accept_terms(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    current_user.accepted_terms = True
    db.commit()
    db.refresh(current_user)
    
    token = create_access_token({
        "sub": current_user.id,
        "role": current_user.role.value if hasattr(current_user.role, 'value') else current_user.role,
        "accepted_terms": True,
    })
    
    return {
        "message": "Términos aceptados",
        "access_token": token,
        "user": {
            "id": current_user.id,
            "name": current_user.name,
            "email": current_user.email,
            "role": current_user.role.value if hasattr(current_user.role, 'value') else current_user.role,
            "avatar": current_user.avatar,
            "is_active": current_user.is_active,
            "accepted_terms": True
        }
    }
