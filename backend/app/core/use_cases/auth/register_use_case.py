import uuid
from app.core.domain.entities.user_entity import UserEntity
from app.core.domain.ports.user_repository import UserRepository
from app.infrastructure.security.utils import hash_password, create_access_token

class RegisterUseCase:
    def __init__(self, user_repo: UserRepository):
        self.user_repo = user_repo

    async def execute(self, name: str, email: str, password: str, role: str) -> dict:
        existing = await self.user_repo.get_by_email(email)
        if existing:
            raise ValueError("Email ya registrado")

        user = UserEntity(
            id=str(uuid.uuid4()),
            name=name,
            email=email,
            password_hash=hash_password(password),
            role=role.upper()
        )
        saved_user = await self.user_repo.save(user)

        token = create_access_token({"sub": saved_user.id, "role": saved_user.role})
        
        return {
            "access_token": token,
            "role": saved_user.role,
            "user_id": saved_user.id,
            "name": saved_user.name,
            "email": saved_user.email,
            "avatar": saved_user.avatar,
        }
