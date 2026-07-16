from cryptography.fernet import Fernet
from passlib.context import CryptContext
import os
import base64
import hashlib
from app.core.domain.ports.encryption_port import EncryptionPort

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class FernetEncryption(EncryptionPort):
    def __init__(self):
        key = os.getenv("FERNET_KEY", "")
        if not key:
            key = Fernet.generate_key().decode()
        if isinstance(key, str):
            key = key.encode()
        self._fernet = Fernet(key)

    def encrypt(self, data: str) -> str:
        return self._fernet.encrypt(data.encode()).decode()

    def decrypt(self, encrypted: str) -> str:
        return self._fernet.decrypt(encrypted.encode()).decode()

    def hash_data(self, data: str) -> str:
        return pwd_context.hash(data)

    def verify_hash(self, data: str, hashed: str) -> bool:
        return pwd_context.verify(data, hashed)


# Singleton
encryption = FernetEncryption()