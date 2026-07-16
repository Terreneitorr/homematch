from typing import List, Optional
from app.core.domain.ports.property_repository_port import PropertyRepositoryPort
from app.core.domain.entities.property_entity import PropertyEntity

class GetPropertiesUseCase:
    def __init__(self, property_repo: PropertyRepositoryPort):
        self.property_repo = property_repo

    async def execute(
        self,
        city: Optional[str] = None,
        operation_type: Optional[str] = None,
        min_price: Optional[float] = None,
        max_price: Optional[float] = None,
        bedrooms: Optional[int] = None
    ) -> List[PropertyEntity]:
        return await self.property_repo.get_all(
            city=city,
            operation_type=operation_type,
            min_price=min_price,
            max_price=max_price
        )
