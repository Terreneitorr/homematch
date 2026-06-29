from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.api.schemas import PropertyInput, ClassificationResult, InferenceResponse
from app.model.classifier import classify_property, train_model
from app.database import get_db, Inference
from typing import List
import uuid

router = APIRouter()

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
def train(db: Session = Depends(get_db)):
    sample_data = [
        {"precio": 800000, "habitaciones": 1, "banos": 1, "metros": 45, "tipo": "Departamento"},
        {"precio": 1200000, "habitaciones": 2, "banos": 1, "metros": 70, "tipo": "Departamento"},
        {"precio": 1850000, "habitaciones": 3, "banos": 2, "metros": 180, "tipo": "Casa"},
        {"precio": 2500000, "habitaciones": 4, "banos": 2, "metros": 220, "tipo": "Casa"},
        {"precio": 3200000, "habitaciones": 4, "banos": 3, "metros": 320, "tipo": "Casa"},
        {"precio": 5000000, "habitaciones": 5, "banos": 4, "metros": 500, "tipo": "Casa"},
        {"precio": 500000, "habitaciones": 1, "banos": 1, "metros": 35, "tipo": "Departamento"},
        {"precio": 950000, "habitaciones": 2, "banos": 2, "metros": 90, "tipo": "Departamento"},
    ]
    train_model(sample_data)
    return {"message": "Modelo entrenado exitosamente", "clusters": 4}

@router.get("/inferences", response_model=List[InferenceResponse])
def get_inferences(db: Session = Depends(get_db)):
    return db.query(Inference).order_by(Inference.fecha.desc()).limit(100).all()