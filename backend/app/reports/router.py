from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User, Report, Property, UserRole
from app.auth.dependencies import get_current_user
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import uuid

router = APIRouter()


class ReportCreate(BaseModel):
    property_id: str
    reason: str
    details: Optional[str] = None


class ReportResponse(BaseModel):
    id: str
    property_id: str
    reporter_id: str
    reason: str
    details: Optional[str] = None
    status: str
    created_at: datetime

    class Config:
        from_attributes = True


def require_admin(current_user: User = Depends(get_current_user)):
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Solo administradores")
    return current_user


@router.post("/")
def create_report(
        data: ReportCreate,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user),
):
    prop = db.query(Property).filter(Property.id == data.property_id).first()
    if not prop:
        raise HTTPException(status_code=404, detail="Propiedad no encontrada")

    report = Report(
        id=str(uuid.uuid4()),
        property_id=data.property_id,
        reporter_id=current_user.id,
        reason=data.reason,
        details=data.details,
    )
    db.add(report)
    db.commit()
    return {"message": "Reporte enviado, gracias por ayudarnos a mantener la plataforma segura"}


@router.get("/", response_model=List[ReportResponse])
def list_reports(
        db: Session = Depends(get_db),
        admin: User = Depends(require_admin),
):
    """Solo el admin puede ver los reportes recibidos."""
    return db.query(Report).order_by(Report.created_at.desc()).all()


@router.put("/{report_id}/status")
def update_report_status(
        report_id: str,
        status: str,
        db: Session = Depends(get_db),
        admin: User = Depends(require_admin),
):
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Reporte no encontrado")
    report.status = status
    db.commit()
    return {"message": "Estado actualizado"}