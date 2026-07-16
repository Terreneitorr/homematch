from app.core.domain.entities.user_entity import UserEntity
from app.core.domain.ports.user_repository import UserRepository
from app.infrastructure.security.utils import create_access_token

class GoogleLoginUseCase:
    def __init__(self, user_repo: UserRepository):
        self.user_repo = user_repo

    async def execute(self, google_id: str, name: str, email: str, avatar: str, role: str) -> dict:
        user = await self.user_repo.get_by_email(email)
        is_new_user = user is None

        if not user:
            user = UserEntity(
                id=google_id,
                name=name,
                email=email,
                avatar=avatar,
                role=role.upper(),
                accepted_terms=False
            )
            user = await self.user_repo.save(user)

        token = create_access_token({
            "sub": user.id,
            "role": user.role,
            "accepted_terms": user.accepted_terms,
        })

        return {
            "access_token": token,
            "role": user.role,
            "user_id": user.id,
            "name": user.name,
            "email": user.email,
            "accepted_terms": user.accepted_terms,
            "is_new_user": is_new_user,
            "avatar": user.avatar,
        }
