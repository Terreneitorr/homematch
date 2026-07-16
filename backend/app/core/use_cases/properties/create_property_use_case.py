import uuid
from app.core.domain.entities.property_entity import PropertyEntity, OperationType, PropertyStatus
from app.core.domain.ports.property_repository_port import PropertyRepositoryPort

class CreatePropertyUseCase:
    def __init__(self, property_repo: PropertyRepositoryPort):
        self.property_repo = property_repo

    async def execute(self, owner_id: str, data: dict) -> PropertyEntity:
        property_entity = PropertyEntity(
            id=str(uuid.uuid4()),
            owner_id=owner_id,
            title=data['title'],
            description=data['description'],
            price=data['price'],
            operation_type=OperationType(data['operation_type']),
            city=data['city'],
            zone=data['zone'],
            area=data['area'],
            colony=data.get('colony'),
            bedrooms=data.get('bedrooms', 1),
            bathrooms=data.get('bathrooms', 1),
            has_garage=data.get('has_garage', False),
            has_garden=data.get('has_garden', False),
            photos=data.get('photos', []),
            status=PropertyStatus.available
        )
        return await self.property_repo.create(property_entity)
