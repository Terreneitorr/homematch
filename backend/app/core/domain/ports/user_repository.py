from abc import ABC, abstractmethod
from typing import Optional, List
from app.core.domain.entities.user_entity import UserEntity

class UserRepository(ABC):
    @abstractmethod
    async def get_by_id(self, user_id: str) -> Optional[UserEntity]:
        pass

    @abstractmethod
    async def get_by_email(self, email: str) -> Optional[UserEntity]:
        pass

    @abstractmethod
    async def save(self, user: UserEntity) -> UserEntity:
        pass

    @abstractmethod
    async def update(self, user: UserEntity) -> UserEntity:
        pass

    @abstractmethod
    async def get_all(self) -> List[UserEntity]:
        pass
