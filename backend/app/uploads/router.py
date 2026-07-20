from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User
from app.auth.dependencies import get_current_user
from pydantic import BaseModel
from typing import Optional

router = APIRouter()


class UserUpdate(BaseModel):
    name: Optional[str] = None
    avatar: Optional[str] = None


class UserResponse(BaseModel):
    id: str
    name: str
    email: str
    role: str
    avatar: Optional[str] = None
    is_active: bool
    accepted_terms: bool = False
    subscription_plan: Optional[str] = None
    subscription_status: Optional[str] = None
    verification_status: Optional[str] = None

    class Config:
        from_attributes = True


@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user


@router.put("/me", response_model=UserResponse)
def update_me(
        data: UserUpdate,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    if data.name:
        current_user.name = data.name
    if data.avatar:
        current_user.avatar = data.avatar
    db.commit()
    db.refresh(current_user)
    return current_user

# Agregar estos imports arriba, junto a los que ya tienes:
# from pydantic import BaseModel
# from app.models import UserRole  (si UserRole no está ya importado)


class VerificationDocumentRequest(BaseModel):
    document_url: str


def require_admin(current_user: User):
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Solo administradores")


@router.post("/me/verification-document")
def submit_verification_document(
        data: VerificationDocumentRequest,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user),
):
    """
    La inmobiliaria sube la URL de su documento (ya subido antes vía
    POST /uploads/, igual que las fotos de propiedades) y queda en espera
    de revisión del admin.
    """
    if current_user.role != UserRole.AGENCY:
        raise HTTPException(
            status_code=403,
            detail="Solo cuentas de tipo Inmobiliaria pueden subir documento de verificación",
        )
    current_user.verification_document_url = data.document_url
    current_user.verification_status = "pending"
    db.commit()
    return {
        "message": "Documento recibido, en espera de revisión",
        "status": "pending",
    }


@router.get("/admin/verifications/pending")
def list_pending_verifications(
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user),
):
    require_admin(current_user)
    users = (
        db.query(User)
        .filter(User.role == UserRole.AGENCY, User.verification_status == "pending")
        .all()
    )
    return [
        {
            "id": u.id,
            "name": u.name,
            "email": u.email,
            "document_url": u.verification_document_url,
        }
        for u in users
    ]


@router.post("/admin/verifications/{user_id}/approve")
def approve_verification(
        user_id: str,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user),
):
    require_admin(current_user)
    target = db.query(User).filter(User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    target.verification_status = "approved"
    db.commit()
    return {"message": "Inmobiliaria verificada"}


@router.post("/admin/verifications/{user_id}/reject")
def reject_verification(
        user_id: str,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user),
):
    require_admin(current_user)
    target = db.query(User).filter(User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    target.verification_status = "rejected"
    db.commit()
    return {"message": "Verificación rechazada"}