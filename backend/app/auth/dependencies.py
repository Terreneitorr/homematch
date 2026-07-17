from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User
from jose import JWTError, jwt
import os

SECRET_KEY = os.getenv("SECRET_KEY", "supersecretkey123homematch")
ALGORITHM = os.getenv("ALGORITHM", "HS256")

bearer_scheme = HTTPBearer()

def get_current_user(
        credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
        db: Session = Depends(get_db)
) -> User:
    try:
        payload = jwt.decode(
            credentials.credentials,
            SECRET_KEY,
            algorithms=[ALGORITHM]
        )
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail="Token inválido")
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=401, detail="Usuario no encontrado")
        if not user.is_active:
            raise HTTPException(status_code=403, detail="Cuenta desactivada")
        return user
    except JWTError:
        raise HTTPException(status_code=401, detail="Token expirado o inválido")