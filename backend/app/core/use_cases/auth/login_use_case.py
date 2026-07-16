from app.core.domain.ports.user_repository import UserRepository
from app.infrastructure.security.utils import verify_password, create_access_token

class LoginUseCase:
    def __init__(self, user_repo: UserRepository):
        self.user_repo = user_repo

    async def execute(self, email: str, password: str) -> dict:
        user = await self.user_repo.get_by_email(email)
        if not user or not verify_password(password, user.password_hash or ""):
            raise ValueError("Credenciales incorrectas")

        token = create_access_token({"sub": user.id, "role": user.role})
        
        return {
            "access_token": token,
            "role": user.role,
            "user_id": user.id,
            "name": user.name,
            "email": user.email,
            "avatar": user.avatar,
            "accepted_terms": user.accepted_terms,
        }
