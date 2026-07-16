from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from app.infrastructure.database.database import get_db
from app.adapters.outbound.postgres_property_repository import PostgresPropertyRepository
from app.core.use_cases.properties.get_properties_use_case import GetPropertiesUseCase
from app.core.use_cases.properties.create_property_use_case import CreatePropertyUseCase
from app.adapters.inbound.property_schemas import PropertyCreate, PropertyUpdate, PropertyResponse
from app.infrastructure.security.dependencies import get_current_user
from app.infrastructure.database.models import User
import uuid
from app.infrastructure.database.models import Notification as NotifModel

router = APIRouter()

@router.get("/", response_model=List[PropertyResponse])
async def get_properties(
        city: Optional[str] = None,
        operation_type: Optional[str] = None,
        min_price: Optional[float] = None,
        max_price: Optional[float] = None,
        bedrooms: Optional[int] = None,
        db: Session = Depends(get_db)
):
    property_repo = PostgresPropertyRepository(db)
    use_case = GetPropertiesUseCase(property_repo)
    return await use_case.execute(city, operation_type, min_price, max_price, bedrooms)

@router.get("/{property_id}", response_model=PropertyResponse)
async def get_property(property_id: str, db: Session = Depends(get_db)):
    property_repo = PostgresPropertyRepository(db)
    prop = await property_repo.get_by_id(property_id)
    if not prop:
        raise HTTPException(status_code=404, detail="Propiedad no encontrada")
    return prop

@router.post("/", response_model=PropertyResponse)
async def create_property(
        data: PropertyCreate,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    property_repo = PostgresPropertyRepository(db)
    use_case = CreatePropertyUseCase(property_repo)
    
    prop = await use_case.execute(current_user.id, data.model_dump())

    # Notificación
    notif = NotifModel(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        title="Propiedad publicada ✓",
        body=f'Tu propiedad "{data.title}" ha sido publicada exitosamente.',
        type="property",
    )
    db.add(notif)
    db.commit()

    return prop

@router.delete("/{property_id}")
async def delete_property(
        property_id: str,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    property_repo = PostgresPropertyRepository(db)
    prop = await property_repo.get_by_id(property_id)
    if not prop:
        raise HTTPException(status_code=404, detail="Propiedad no encontrada")
    if prop.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Sin permiso")
    
    await property_repo.delete(property_id)
    return {"message": "Propiedad eliminada"}
