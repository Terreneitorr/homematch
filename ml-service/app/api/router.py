from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db, Inference
from app.model.classifier import (
    classify_property, train_property_model,
    get_collaborative_recommendations, train_user_model,
    build_user_vector, load_user_model, load_model
)
from pydantic import BaseModel
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


class TrainRequest(BaseModel):
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
def train(request: TrainRequest, db: Session = Depends(get_db)):
    """
    Entrena K-Means sobre propiedades para clasificación.
    Usa datos reales de la BD o datos proporcionados.
    """
    if request.data:
        data = request.data
    else:
        inferences = db.query(Inference).all()
        if inferences:
            data = [
                {
                    "precio": inf.precio,
                    "habitaciones": inf.habitaciones,
                    "banos": inf.banos,
                    "metros": inf.metros,
                    "tipo": inf.tipo,
                }
                for inf in inferences
            ]
        else:
            data = []

    model, scaler = train_property_model(data) if data else (None, None)

    if model:
        return {
            "message": "Modelo de propiedades entrenado",
            "n_clusters": model.n_clusters,
            "samples": len(data),
        }
    return {"message": "Sin datos suficientes para entrenar"}


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