from abc import ABC, abstractmethod
from typing import List, Optional
from app.core.domain.entities.property_entity import PropertyEntity

class PropertyRepositoryPort(ABC):

    @abstractmethod
    async def get_all(
            self,
            city: Optional[str] = None,
            operation_type: Optional[str] = None,
            min_price: Optional[float] = None,
            max_price: Optional[float] = None,
    ) -> List[PropertyEntity]:
        pass

    @abstractmethod
    async def get_by_id(self, property_id: str) -> Optional[PropertyEntity]:
        pass

    @abstractmethod
    async def create(self, entity: PropertyEntity) -> PropertyEntity:
        pass

    @abstractmethod
    async def update(self, entity: PropertyEntity) -> PropertyEntity:
        pass

    @abstractmethod
    async def delete(self, property_id: str) -> bool:
        pass

    @abstractmethod
    async def get_by_owner(self, owner_id: str) -> List[PropertyEntity]:
        pass
