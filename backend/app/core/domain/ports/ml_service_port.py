from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import List


@dataclass
class ClassificationResult:
    cluster: int
    segmento: str
    score: float


@dataclass
class RecommendationResult:
    property_id: str
    similarity_score: float


class MLServicePort(ABC):

    @abstractmethod
    async def classify_property(
            self,
            precio: float,
            habitaciones: int,
            banos: int,
            metros: float,
            tipo: str,
    ) -> ClassificationResult:
        pass

    @abstractmethod
    async def get_recommendations(
            self,
            favorite_ids: List[str],
            limit: int = 6,
    ) -> List[RecommendationResult]:
        pass

    @abstractmethod
    async def train_model(self, data: List[dict]) -> dict:
        pass