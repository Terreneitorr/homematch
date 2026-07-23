from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from app.database import get_db
from app.models import Property, OperationType, PropertyStatus
from app.auth.dependencies import get_current_user
from app.models import User
from app.properties.schemas import PropertyCreate, PropertyUpdate, PropertyResponse
from app.properties.semantic_search import semantic_search as run_semantic_search
from app.notifications.router import notify_new_property
import uuid

router = APIRouter()

@router.get("/", response_model=List[PropertyResponse])
def get_properties(
        city: Optional[str] = None,
        operation_type: Optional[str] = None,
        min_price: Optional[float] = None,
        max_price: Optional[float] = None,
        bedrooms: Optional[int] = None,
        db: Session = Depends(get_db)
):
    query = db.query(Property).filter(Property.status == PropertyStatus.available)
    if city:
        query = query.filter(Property.city.ilike(f"%{city}%"))
    if operation_type:
        query = query.filter(Property.operation_type == operation_type)
    if min_price:
        query = query.filter(Property.price >= min_price)
    if max_price:
        query = query.filter(Property.price <= max_price)
    if bedrooms:
        query = query.filter(Property.bedrooms >= bedrooms)
    return query.order_by(Property.created_at.desc()).all()

@router.get("/search")
def search_properties(
        q: str,
        limit: int = 10,
        db: Session = Depends(get_db),
):
    """
    Búsqueda semántica en texto libre.
    Ej: /properties/search?q=casa con jardín cerca del centro barata

    IMPORTANTE: este endpoint debe ir declarado ANTES de /{property_id}
    en el archivo. FastAPI matchea rutas en orden de declaración, y
    /{property_id} es un comodín que intercepta cualquier string
    (incluyendo "search") si aparece primero.
    """
    # Solo propiedades disponibles, igual que en GET /properties/
    properties = db.query(Property).filter(Property.status == PropertyStatus.available).all()
    results = run_semantic_search(query=q, properties=properties, top_n=limit)
    return results

@router.get("/{property_id}", response_model=PropertyResponse)
def get_property(property_id: str, db: Session = Depends(get_db)):
    prop = db.query(Property).filter(Property.id == property_id).first()
    if not prop:
        raise HTTPException(status_code=404, detail="Propiedad no encontrada")
    return prop

@router.post("/", response_model=PropertyResponse)
def create_property(
        data: PropertyCreate,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    prop = Property(
        id=str(uuid.uuid4()),
        owner_id=current_user.id,
        title=data.title,
        description=data.description,
        price=data.price,
        operation_type=OperationType(data.operation_type),
        city=data.city,
        zone=data.zone,
        colony=data.colony,
        bedrooms=data.bedrooms,
        bathrooms=data.bathrooms,
        has_garage=data.has_garage,
        has_garden=data.has_garden,
        area=data.area,
        photos=data.photos,
    )
    db.add(prop)
    db.commit()
    db.refresh(prop)

    # Avisa a los compradores que hay una propiedad nueva.
    # No debe tumbar la creación de la propiedad si algo sale mal aquí.
    try:
        notify_new_property(
            db=db,
            property_title=prop.title,
            property_id=prop.id,
            exclude_owner_id=prop.owner_id,
        )
    except Exception:
        pass

    return prop

@router.put("/{property_id}", response_model=PropertyResponse)
def update_property(
        property_id: str,
        data: PropertyUpdate,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    prop = db.query(Property).filter(Property.id == property_id).first()
    if not prop:
        raise HTTPException(status_code=404, detail="No encontrada")
    if prop.owner_id != current_user.id and current_user.role.value != "ADMIN":
        raise HTTPException(status_code=403, detail="Sin permiso")
    for field, value in data.model_dump(exclude_none=True).items():
        setattr(prop, field, value)
    db.commit()
    db.refresh(prop)
    return prop

@router.delete("/{property_id}")
def delete_property(
        property_id: str,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    prop = db.query(Property).filter(Property.id == property_id).first()
    if not prop:
        raise HTTPException(status_code=404, detail="No encontrada")
    if prop.owner_id != current_user.id and current_user.role.value != "ADMIN":
        raise HTTPException(status_code=403, detail="Sin permiso")
    db.delete(prop)
    db.commit()
    return {"message": "Eliminada"}