from app.model.classifier import (
    classify_property, train_property_model,
    get_collaborative_recommendations, train_user_model,
    _build_user_vector, load_user_model
)
from sqlalchemy.orm import Session
from app.database import get_db, Inference
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import uuid

class CollaborativeRequest(BaseModel):
    user_favorites: List[Dict[str, Any]]
    all_properties: List[Dict[str, Any]]
    all_users_favorites: List[List[Dict[str, Any]]]
    limit: int = 6

@router.post("/collaborative-recommend")
def collaborative_recommend(request: CollaborativeRequest):
    """
    Filtrado colaborativo real — como dijo el profe:
    Encuentra usuarios similares y recomienda lo que a ellos les gustó
    """
    recommendations = get_collaborative_recommendations(
        user_favorites=request.user_favorites,
        all_properties=request.all_properties,
        all_users_favorites=request.all_users_favorites,
        limit=request.limit,
    )
    return {"recommendations": recommendations}


@router.post("/train-user-model")
def train_users(db: Session = Depends(get_db)):
    """Entrena el modelo de usuarios para filtrado colaborativo"""
    # En producción estos vendrían de la BD de favoritos
    # Por ahora usamos las inferencias como proxy
    inferences = db.query(Inference).all()
    if not inferences:
        return {"message": "Sin datos para entrenar"}

    # Simular vectores de usuarios
    user_vectors = []
    for inf in inferences:
        user_vectors.append({
            "avg_precio": inf.precio,
            "avg_habitaciones": inf.habitaciones,
            "avg_metros": inf.metros,
            "num_favoritos": 1,
            "tipo_predominante": 0,
        })

    model, scaler = train_user_model(user_vectors)
    if model:
        return {
            "message": "Modelo de usuarios entrenado",
            "n_user_clusters": model.n_clusters,
            "users_used": len(user_vectors),
        }
    return {"message": "Datos insuficientes"}