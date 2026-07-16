from typing import Optional, List
from sqlalchemy.orm import Session
from app.core.domain.entities.user_entity import UserEntity
from app.core.domain.ports.user_repository import UserRepository
from app.infrastructure.database.models import User

class PostgresUserRepository(UserRepository):
    def __init__(self, db: Session):
        self._db = db

    def _to_entity(self, model: User) -> UserEntity:
        return UserEntity(
            id=model.id,
            name=model.name,
            email=model.email,
            role=model.role.value if hasattr(model.role, 'value') else model.role,
            password_hash=model.password_hash,
            avatar=model.avatar,
            is_active=model.is_active,
            accepted_terms=model.accepted_terms,
            created_at=model.created_at
        )

    async def get_by_id(self, user_id: str) -> Optional[UserEntity]:
        model = self._db.query(User).filter(User.id == user_id).first()
        return self._to_entity(model) if model else None

    async def get_by_email(self, email: str) -> Optional[UserEntity]:
        model = self._db.query(User).filter(User.email == email).first()
        return self._to_entity(model) if model else None

    async def save(self, user: UserEntity) -> UserEntity:
        model = User(
            id=user.id,
            name=user.name,
            email=user.email,
            password_hash=user.password_hash,
            role=user.role,
            avatar=user.avatar,
            is_active=user.is_active,
            accepted_terms=user.accepted_terms
        )
        self._db.add(model)
        self._db.commit()
        self._db.refresh(model)
        return self._to_entity(model)

    async def update(self, user: UserEntity) -> UserEntity:
        model = self._db.query(User).filter(User.id == user.id).first()
        if model:
            model.name = user.name
            model.avatar = user.avatar
            model.is_active = user.is_active
            model.accepted_terms = user.accepted_terms
            self._db.commit()
            self._db.refresh(model)
        return self._to_entity(model) if model else user

    async def get_all(self) -> List[UserEntity]:
        models = self._db.query(User).all()
        return [self._to_entity(m) for m in models]
