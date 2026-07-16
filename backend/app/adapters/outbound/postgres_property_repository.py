from typing import List, Optional
from sqlalchemy.orm import Session
from app.core.domain.entities.property_entity import (
    PropertyEntity, OperationType, PropertyStatus
)
from app.core.domain.ports.property_repository_port import PropertyRepositoryPort
from app.infrastructure.database.models import Property
import uuid
from datetime import datetime


class PostgresPropertyRepository(PropertyRepositoryPort):
    def __init__(self, db: Session):
        self._db = db

    def _to_entity(self, model: Property) -> PropertyEntity:
        photos = model.photos or []
        if isinstance(photos, str):
            import json
            try:
                photos = json.loads(photos)
            except Exception:
                photos = []

        return PropertyEntity(
            id=model.id,
            owner_id=model.owner_id,
            title=model.title,
            description=model.description,
            price=model.price,
            operation_type=OperationType(model.operation_type),
            status=PropertyStatus(model.status),
            city=model.city,
            zone=model.zone,
            colony=model.colony,
            bedrooms=model.bedrooms,
            bathrooms=model.bathrooms,
            has_garage=model.has_garage,
            has_garden=model.has_garden,
            area=model.area,
            photos=photos,
            cluster=model.cluster,
            created_at=model.created_at,
        )

    async def get_all(
            self,
            city: Optional[str] = None,
            operation_type: Optional[str] = None,
            min_price: Optional[float] = None,
            max_price: Optional[float] = None,
    ) -> List[PropertyEntity]:
        query = self._db.query(Property).filter(
            Property.status == "available"
        )
        if city:
            query = query.filter(Property.city.ilike(f"%{city}%"))
        if operation_type:
            query = query.filter(Property.operation_type == operation_type)
        if min_price:
            query = query.filter(Property.price >= min_price)
        if max_price:
            query = query.filter(Property.price <= max_price)
        return [self._to_entity(p) for p in query.all()]

    async def get_by_id(self, property_id: str) -> Optional[PropertyEntity]:
        model = self._db.query(Property).filter(
            Property.id == property_id
        ).first()
        return self._to_entity(model) if model else None

    async def create(self, entity: PropertyEntity) -> PropertyEntity:
        model = Property(
            id=str(uuid.uuid4()),
            owner_id=entity.owner_id,
            title=entity.title,
            description=entity.description,
            price=entity.price,
            operation_type=entity.operation_type.value,
            status=entity.status.value,
            city=entity.city,
            zone=entity.zone,
            colony=entity.colony,
            bedrooms=entity.bedrooms,
            bathrooms=entity.bathrooms,
            has_garage=entity.has_garage,
            has_garden=entity.has_garden,
            area=entity.area,
            photos=entity.photos,
            cluster=entity.cluster,
        )
        self._db.add(model)
        self._db.commit()
        self._db.refresh(model)
        return self._to_entity(model)

    async def update(self, entity: PropertyEntity) -> PropertyEntity:
        model = self._db.query(Property).filter(
            Property.id == entity.id
        ).first()
        if not model:
            raise ValueError("Propiedad no encontrada")
        model.title = entity.title
        model.price = entity.price
        model.status = entity.status.value
        model.cluster = entity.cluster
        self._db.commit()
        self._db.refresh(model)
        return self._to_entity(model)

    async def delete(self, property_id: str) -> bool:
        model = self._db.query(Property).filter(
            Property.id == property_id
        ).first()
        if not model:
            return False
        self._db.delete(model)
        self._db.commit()
        return True

    async def get_by_owner(self, owner_id: str) -> List[PropertyEntity]:
        models = self._db.query(Property).filter(
            Property.owner_id == owner_id
        ).all()
        return [self._to_entity(m) for m in models]