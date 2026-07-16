from typing import List, Optional
from app.core.domain.entities.property_entity import PropertyEntity
from app.core.domain.ports.property_repository_port import PropertyRepositoryPort
from app.core.domain.ports.ml_service_port import MLServicePort


class GetPropertiesUseCase:
    def __init__(self, repo: PropertyRepositoryPort):
        self._repo = repo

    async def execute(
            self,
            city: Optional[str] = None,
            operation_type: Optional[str] = None,
            min_price: Optional[float] = None,
            max_price: Optional[float] = None,
    ) -> List[PropertyEntity]:
        return await self._repo.get_all(
            city=city,
            operation_type=operation_type,
            min_price=min_price,
            max_price=max_price,
        )


class CreatePropertyUseCase:
    def __init__(
            self,
            repo: PropertyRepositoryPort,
            ml_service: MLServicePort,
    ):
        self._repo = repo
        self._ml = ml_service

    async def execute(self, entity: PropertyEntity) -> PropertyEntity:
        # Clasificar con ML antes de guardar
        try:
            result = await self._ml.classify_property(
                precio=entity.price,
                habitaciones=entity.bedrooms,
                banos=entity.bathrooms,
                metros=entity.area,
                tipo="Casa" if "casa" in entity.title.lower() else "Departamento",
            )
            entity.cluster = result.cluster
        except Exception:
            entity.cluster = None

        return await self._repo.create(entity)


class GetRecommendationsUseCase:
    def __init__(
            self,
            repo: PropertyRepositoryPort,
            ml_service: MLServicePort,
    ):
        self._repo = repo
        self._ml = ml_service

    async def execute(
            self,
            favorite_ids: List[str],
            limit: int = 6,
    ) -> List[PropertyEntity]:
        if not favorite_ids:
            return await self._repo.get_all()

        recommendations = await self._ml.get_recommendations(
            favorite_ids=favorite_ids,
            limit=limit,
        )

        properties = []
        for rec in recommendations:
            prop = await self._repo.get_by_id(rec.property_id)
            if prop:
                properties.append(prop)

        return properties