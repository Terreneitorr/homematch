from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.infrastructure.database.database import get_db
from app.infrastructure.database.models import Property, PropertyStatus

router = APIRouter()

@router.get("/")
def get_analytics(db: Session = Depends(get_db)):
    total = db.query(Property).filter(Property.status == PropertyStatus.available).count()
    avg_price = db.query(func.avg(Property.price)).filter(
        Property.status == PropertyStatus.available
    ).scalar()
    by_city = db.query(Property.city, func.count(Property.id)).group_by(Property.city).all()
    by_type = db.query(Property.operation_type, func.count(Property.id)).group_by(Property.operation_type).all()

    return {
        "total_properties": total,
        "average_price": round(avg_price or 0, 2),
        "by_city": [{"city": c, "count": n} for c, n in by_city],
        "by_operation_type": [{"type": t, "count": n} for t, n in by_type],
    }