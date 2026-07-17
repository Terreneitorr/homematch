from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db, Inference
from app.model.classifier import (
    classify_property, train_property_model,
    get_collaborative_recommendations, train_user_model,
    build_user_vector, load_user_model, load_model
)
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
import uuid
import os

router = APIRouter()


class PropertyInput(BaseModel):
    precio: float
    habitaciones: int
    banos: int
    metros: float
    tipo: str = "Casa"
    property_id: Optional[str] = None


class ClassificationResult(BaseModel):
    cluster: int
    segmento: str


class PropertySample(BaseModel):
    """Muestra de propiedad usada para (re)entrenar el modelo de K-Means."""
    precio: float = Field(gt=0, description="Precio de la propiedad, debe ser mayor a 0")
    habitaciones: int = Field(ge=0, description="Número de habitaciones")
    banos: int = Field(ge=0, description="Número de baños")
    metros: float = Field(gt=0, description="Metros cuadrados, debe ser mayor a 0")
    tipo: str = "Casa"


class TrainPropertyRequest(BaseModel):
    """Body para /train-model. Si no se manda 'data', se usa la BD o datos base."""
    data: Optional[List[PropertySample]] = None


class TrainRequest(BaseModel):
    """Body genérico usado por /train-user-model (vectores de usuario, no propiedades)."""
    data: Optional[List[dict]] = None


class CollaborativeRequest(BaseModel):
    user_favorites: List[Dict[str, Any]]
    all_properties: List[Dict[str, Any]]
    all_users_data: List[Dict[str, Any]] = []
    limit: int = 6


@router.post("/classify-property", response_model=ClassificationResult)
def classify(data: PropertyInput, db: Session = Depends(get_db)):
    """Clasifica una propiedad en un segmento usando K-Means."""
    cluster, segmento = classify_property(
        precio=data.precio,
        habitaciones=data.habitaciones,
        banos=data.banos,
        metros=data.metros,
        tipo=data.tipo,
    )

    # Guardar inferencia
    inference = Inference(
        id=data.property_id or str(uuid.uuid4()),
        precio=data.precio,
        habitaciones=data.habitaciones,
        banos=data.banos,
        metros=data.metros,
        tipo=data.tipo,
        cluster=cluster,
        segmento=segmento,
    )
    try:
        db.merge(inference)
        db.commit()
    except Exception:
        db.rollback()

    return ClassificationResult(cluster=cluster, segmento=segmento)


@router.post("/train-model")
def train(request: TrainPropertyRequest, db: Session = Depends(get_db)):
    data = []
    source = "base_data"

    if request.data and len(request.data) > 0:
        data = [sample.model_dump() for sample in request.data]
        source = "request"
    else:
        try:
            inferences = db.query(Inference).all()
            if inferences:
                data = [
                    {
                        "precio": inf.precio,
                        "habitaciones": inf.habitaciones,
                        "banos": inf.banos,
                        "metros": inf.metros,
                        "tipo": inf.tipo or "Casa",
                    }
                    for inf in inferences
                    if inf.precio and inf.metros
                ]
                if data:
                    source = "database"
        except Exception:
            pass

    if not data:
        data = [
            {"precio": 450000, "habitaciones": 1, "banos": 1, "metros": 45, "tipo": "Departamento"},
            {"precio": 850000, "habitaciones": 2, "banos": 1, "metros": 75, "tipo": "Departamento"},
            {"precio": 1200000, "habitaciones": 2, "banos": 2, "metros": 85, "tipo": "Departamento"},
            {"precio": 1500000, "habitaciones": 3, "banos": 2, "metros": 130, "tipo": "Casa"},
            {"precio": 1850000, "habitaciones": 3, "banos": 2, "metros": 180, "tipo": "Casa"},
            {"precio": 2200000, "habitaciones": 4, "banos": 2, "metros": 220, "tipo": "Casa"},
            {"precio": 3200000, "habitaciones": 4, "banos": 3, "metros": 320, "tipo": "Casa"},
            {"precio": 4500000, "habitaciones": 5, "banos": 4, "metros": 450, "tipo": "Casa"},
            {"precio": 980000, "habitaciones": 3, "banos": 2, "metros": 120, "tipo": "Casa"},
            {"precio": 650000, "habitaciones": 2, "banos": 1, "metros": 60, "tipo": "Departamento"},
        ]

    model, scaler = train_property_model(data)

    if model:
        return {
            "message": "Modelo entrenado exitosamente",
            "n_clusters": model.n_clusters,
            "samples_used": len(data),
            "source": source,
        }
    return {"message": "Error entrenando modelo", "samples": len(data)}


@router.post("/collaborative-recommend")
def collaborative_recommend(request: CollaborativeRequest):
    """
    Filtrado Colaborativo real — algoritmo del profe:

    1. Construye vector del usuario actual con sus favoritos
    2. Entrena K-Means sobre TODOS los usuarios
    3. Encuentra usuarios similares (mismo cluster)
    4. Recomienda lo que a esos usuarios similares les gustó
    5. Excluye propiedades que ya tiene el usuario
    """
    recommendations = get_collaborative_recommendations(
        current_user_favorites=request.user_favorites,
        all_properties=request.all_properties,
        all_users_data=request.all_users_data,
        limit=request.limit,
    )
    return {
        "recommendations": recommendations,
        "algorithm": "collaborative_filtering",
        "users_analyzed": len(request.all_users_data),
        "favorites_used": len(request.user_favorites),
    }


@router.post("/train-user-model")
def train_users(request: TrainRequest):
    """
    Entrena K-Means sobre usuarios para filtrado colaborativo.
    Recibe vectores de usuarios pre-calculados.
    """
    if not request.data or len(request.data) < 2:
        return {"message": "Se necesitan mínimo 2 usuarios con favoritos"}

    model, scaler = train_user_model(request.data)
    if model:
        return {
            "message": "Modelo de usuarios entrenado",
            "n_clusters": model.n_clusters,
            "users_used": len(request.data),
        }
    return {"message": "Error entrenando modelo"}


@router.get("/model-stats")
def model_stats(db: Session = Depends(get_db)):
    """Estadísticas de los modelos entrenados."""
    prop_model, _ = load_model()
    user_model, _ = load_user_model()
    total_inferences = db.query(Inference).count()

    return {
        "property_model": {
            "trained": prop_model is not None,
            "n_clusters": prop_model.n_clusters if prop_model else 0,
        },
        "user_model": {
            "trained": user_model is not None,
            "n_clusters": user_model.n_clusters if user_model else 0,
        },
        "total_classifications": total_inferences,
    }


@router.get("/inferences")
def get_inferences(db: Session = Depends(get_db)):
    """Historial de clasificaciones realizadas."""
    return db.query(Inference).order_by(
        Inference.fecha.desc()
    ).limit(50).all()