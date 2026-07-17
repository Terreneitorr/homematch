from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User, UserRole
from app.auth.schemas import RegisterRequest, LoginRequest, GoogleLoginRequest, TokenResponse
from app.auth.utils import hash_password, verify_password, create_access_token
from app.auth.dependencies import get_current_user
import uuid

router = APIRouter()

@router.post("/register", response_model=TokenResponse)
def register(data: RegisterRequest, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == data.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email ya registrado")
    user = User(
        id=str(uuid.uuid4()),
        name=data.name,
        email=data.email,
        password_hash=hash_password(data.password),
        role=UserRole(data.role.upper()) if data.role.upper() in UserRole.__members__ else UserRole.USER,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    token = create_access_token({"sub": user.id, "role": user.role.value})
    return TokenResponse(
        access_token=token, role=user.role.value,
        user_id=user.id, name=user.name, email=user.email,
    )

@router.post("/login", response_model=TokenResponse)
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()
    if not user or not verify_password(data.password, user.password_hash or ""):
        raise HTTPException(status_code=401, detail="Credenciales incorrectas")
    token = create_access_token({"sub": user.id, "role": user.role.value})
    return TokenResponse(
        access_token=token, role=user.role.value,
        user_id=user.id, name=user.name, email=user.email,
        accepted_terms=user.accepted_terms,
    )

@router.post("/google", response_model=TokenResponse)
def google_login(data: GoogleLoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()
    is_new = user is None
    if not user:
        role_map = {"USER": UserRole.USER, "SELLER": UserRole.SELLER,
                    "AGENCY": UserRole.AGENCY, "ADMIN": UserRole.ADMIN}
        user = User(
            id=data.google_id, name=data.name, email=data.email,
            avatar=data.avatar,
            role=role_map.get(data.role.upper(), UserRole.USER),
            accepted_terms=False,
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    token = create_access_token({
        "sub": user.id, "role": user.role.value,
        "accepted_terms": user.accepted_terms,
    })
    return TokenResponse(
        access_token=token, role=user.role.value,
        user_id=user.id, name=user.name, email=user.email,
        accepted_terms=user.accepted_terms, is_new_user=is_new,
    )

@router.post("/accept-terms")
def accept_terms(
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    current_user.accepted_terms = True
    db.commit()
    token = create_access_token({
        "sub": current_user.id,
        "role": current_user.role.value,
        "accepted_terms": True,
    })
    return {"message": "Términos aceptados", "access_token": token}

@router.post("/refresh-token", response_model=TokenResponse)
def refresh_token(
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    token = create_access_token({
        "sub": current_user.id,
        "role": current_user.role.value,
        "accepted_terms": current_user.accepted_terms,
    })
    return TokenResponse(
        access_token=token, role=current_user.role.value,
        user_id=current_user.id, name=current_user.name,
        email=current_user.email, accepted_terms=current_user.accepted_terms,
    )