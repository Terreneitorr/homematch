from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.database import get_db
from app.models import User, UserRole, Property, SearchHistory, Appointment
from app.auth.dependencies import get_current_user
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime, timedelta
import uuid

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
    accepted_terms: bool
    created_at: datetime
    subscription_plan: Optional[str] = None
    subscription_status: Optional[str] = None
    verification_status: Optional[str] = None

    class Config:
        from_attributes = True

class AdminUserAction(BaseModel):
    reason: Optional[str] = None

class VerificationDocumentRequest(BaseModel):
    document_url: str

router = APIRouter()

def require_admin(current_user: User = Depends(get_current_user)):
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Solo administradores")
    return current_user

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

@router.get("/", response_model=List[UserResponse])
def get_all_users(
        db: Session = Depends(get_db),
        admin: User = Depends(require_admin)
):
    return db.query(User).order_by(User.created_at.desc()).all()

@router.get("/stats")
def get_user_stats(
        db: Session = Depends(get_db),
        admin: User = Depends(require_admin)
):
    total = db.query(User).count()
    active = db.query(User).filter(User.is_active == True).count()
    by_role = {}
    for role in UserRole:
        count = db.query(User).filter(User.role == role).count()
        by_role[role.value] = count
    return {
        "total": total,
        "active": active,
        "inactive": total - active,
        "by_role": by_role,
    }

@router.put("/{user_id}/activate")
def activate_user(
        user_id: str,
        db: Session = Depends(get_db),
        admin: User = Depends(require_admin)
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    user.is_active = True
    db.commit()
    return {"message": f"Usuario {user.name} activado"}

@router.put("/{user_id}/deactivate")
def deactivate_user(
        user_id: str,
        data: AdminUserAction,
        db: Session = Depends(get_db),
        admin: User = Depends(require_admin)
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    if user.role == UserRole.ADMIN:
        raise HTTPException(status_code=400, detail="No puedes desactivar un admin")
    user.is_active = False
    db.commit()
    return {"message": f"Usuario {user.name} desactivado. Razón: {data.reason}"}

@router.put("/{user_id}/role")
def change_role(
        user_id: str,
        role: str,
        db: Session = Depends(get_db),
        admin: User = Depends(require_admin)
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    try:
        user.role = UserRole(role.upper())
    except ValueError:
        raise HTTPException(status_code=400, detail="Rol inválido")
    db.commit()
    return {"message": f"Rol de {user.name} cambiado a {role}"}

@router.delete("/{user_id}")
def delete_user_permanent(
        user_id: str,
        db: Session = Depends(get_db),
        admin: User = Depends(require_admin)
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    if user.role == UserRole.ADMIN:
        raise HTTPException(status_code=400, detail="No puedes eliminar un admin")
    db.delete(user)
    db.commit()
    return {"message": f"Usuario {user.name} eliminado permanentemente"}


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
        admin: User = Depends(require_admin),
):
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
        admin: User = Depends(require_admin),
):
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
        admin: User = Depends(require_admin),
):
    target = db.query(User).filter(User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    target.verification_status = "rejected"
    db.commit()
    return {"message": "Verificación rechazada"}


@router.get("/admin/dashboard-stats")
def admin_dashboard_stats(
        db: Session = Depends(get_db),
        admin: User = Depends(require_admin),
):
    """
    Estadísticas de uso para el dashboard del admin:
    - Total de propiedades publicadas
    - Quiénes publican más (top 10 usuarios por número de propiedades)
    - Actividad de los últimos 7 días (propiedades nuevas, búsquedas, citas)
    """
    total_properties = db.query(Property).count()

    top_publishers_raw = (
        db.query(Property.owner_id, User.name, func.count(Property.id).label("total"))
        .join(User, User.id == Property.owner_id)
        .group_by(Property.owner_id, User.name)
        .order_by(func.count(Property.id).desc())
        .limit(10)
        .all()
    )
    top_publishers = [
        {"owner_id": owner_id, "name": name, "properties_count": total}
        for owner_id, name, total in top_publishers_raw
    ]

    today = datetime.utcnow().date()
    activity = []
    for i in range(6, -1, -1):
        day = today - timedelta(days=i)
        properties_count = db.query(Property).filter(
            func.date(Property.created_at) == day
        ).count()
        searches_count = db.query(SearchHistory).filter(
            func.date(SearchHistory.searched_at) == day
        ).count()
        appointments_count = db.query(Appointment).filter(
            func.date(Appointment.created_at) == day
        ).count()
        activity.append({
            "date": day.isoformat(),
            "properties": properties_count,
            "searches": searches_count,
            "appointments": appointments_count,
        })

    return {
        "total_properties": total_properties,
        "top_publishers": top_publishers,
        "activity_last_7_days": activity,
    }