from abc import ABC, abstractmethod


class EncryptionPort(ABC):

    @abstractmethod
    def encrypt(self, data: str) -> str:
        pass

    @abstractmethod
    def decrypt(self, encrypted: str) -> str:
        pass

    @abstractmethod
    def hash_data(self, data: str) -> str:
        pass

    @abstractmethod
    def verify_hash(self, data: str, hashed: str) -> bool:
        pass