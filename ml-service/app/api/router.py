from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.api.schemas import PropertyInput, ClassificationResult, InferenceResponse
from app.model.classifier import classify_property, train_model
from app.database import get_db, Inference
from pydantic import BaseModel
from typing import List, Optional
import uuid

router = APIRouter()


class TrainRequest(BaseModel):
    data: Optional[List[dict]] = None


class RecommendRequest(BaseModel):
    favorite_ids: List[str]
    limit: int = 6


class RecommendationItem(BaseModel):
    property_id: str
    score: float


@router.post("/classify-property", response_model=ClassificationResult)
def classify(data: PropertyInput, db: Session = Depends(get_db)):
    cluster, segmento = classify_property(
        precio=data.precio,
        habitaciones=data.habitaciones,
        banos=data.banos,
        metros=data.metros,
        tipo=data.tipo,
    )

    inference = Inference(
        id=str(uuid.uuid4()),
        precio=data.precio,
        habitaciones=data.habitaciones,
        banos=data.banos,
        metros=data.metros,
        tipo=data.tipo,
        cluster=cluster,
        segmento=segmento,
    )
    db.add(inference)
    db.commit()

    return ClassificationResult(cluster=cluster, segmento=segmento)


@router.post("/train-model")
def train(request: TrainRequest = TrainRequest(), db: Session = Depends(get_db)):
    """Entrena con datos reales de la BD o datos proporcionados"""
    if request.data:
        data = request.data
    else:
        # Usar historial de inferencias como datos de entrenamiento
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

    kmeans, scaler = train_model(data)
    n_clusters = kmeans.n_clusters

    return {
        "message": "Modelo entrenado exitosamente",
        "clusters": n_clusters,
        "samples_used": len(data),
        "segment_names": {
            str(i): name
            for i, name in {
                0: "Departamento Económico",
                1: "Casa Familiar",
                2: "Residencia Premium",
                3: "Propiedad de Inversión",
            }.items()
            if i < n_clusters
        }
    }


@router.post("/recommend")
def recommend(
        request: RecommendRequest,
        db: Session = Depends(get_db)
):
    """Recomendaciones basadas en favoritos usando similitud de clusters"""
    if not request.favorite_ids:
        return {"recommendations": []}

    # Obtener clusters de los favoritos
    fav_inferences = db.query(Inference).filter(
        Inference.id.in_(request.favorite_ids)
    ).all()

    if not fav_inferences:
        return {"recommendations": []}

    # Cluster más común en favoritos
    from collections import Counter
    cluster_counts = Counter(inf.cluster for inf in fav_inferences)
    target_cluster = cluster_counts.most_common(1)[0][0]

    # Propiedades con cluster similar no en favoritos
    similar = db.query(Inference).filter(
        Inference.cluster == target_cluster,
        ~Inference.id.in_(request.favorite_ids)
    ).limit(request.limit).all()

    return {
        "recommendations": [
            {
                "property_id": inf.id,
                "score": 1.0 - abs(inf.cluster - target_cluster) * 0.25,
                "segmento": inf.segmento,
            }
            for inf in similar
        ]
    }


@router.get("/inferences", response_model=List[InferenceResponse])
def get_inferences(db: Session = Depends(get_db)):
    return db.query(Inference).order_by(
        Inference.fecha.desc()
    ).limit(100).all()


@router.get("/model-stats")
def model_stats(db: Session = Depends(get_db)):
    """Estadísticas del modelo entrenado"""
    from app.model.classifier import load_model
    import os

    model, scaler = load_model()
    model_exists = model is not None
    total_inferences = db.query(Inference).count()

    return {
        "model_trained": model_exists,
        "n_clusters": model.n_clusters if model_exists else 0,
        "total_inferences": total_inferences,
        "model_path": os.path.exists("/app/model.pkl"),
    }