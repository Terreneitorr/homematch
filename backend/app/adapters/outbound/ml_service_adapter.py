import httpx
import os
from typing import List
from app.core.domain.ports.ml_service_port import (
    MLServicePort, ClassificationResult, RecommendationResult
)

ML_URL = os.getenv("ML_URL", "http://ml-service:8001")


class MLServiceAdapter(MLServicePort):

    async def classify_property(
            self,
            precio: float,
            habitaciones: int,
            banos: int,
            metros: float,
            tipo: str,
    ) -> ClassificationResult:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(
                f"{ML_URL}/classify-property",
                json={
                    "precio": precio,
                    "habitaciones": habitaciones,
                    "banos": banos,
                    "metros": metros,
                    "tipo": tipo,
                },
            )
            data = response.json()
            return ClassificationResult(
                cluster=data["cluster"],
                segmento=data["segmento"],
                score=data.get("score", 0.0),
            )

    async def get_recommendations(
            self,
            favorite_ids: List[str],
            limit: int = 6,
    ) -> List[RecommendationResult]:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(
                f"{ML_URL}/recommend",
                json={"favorite_ids": favorite_ids, "limit": limit},
            )
            data = response.json()
            return [
                RecommendationResult(
                    property_id=r["property_id"],
                    similarity_score=r["score"],
                )
                for r in data.get("recommendations", [])
            ]

    async def train_model(self, data: List[dict]) -> dict:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                f"{ML_URL}/train-model",
                json={"data": data},
            )
            return response.json()