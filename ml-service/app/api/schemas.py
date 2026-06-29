from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class PropertyInput(BaseModel):
    precio: float
    habitaciones: int
    banos: int
    metros: float
    tipo: str

class ClassificationResult(BaseModel):
    cluster: int
    segmento: str

class InferenceResponse(BaseModel):
    id: str
    precio: float
    habitaciones: int
    banos: int
    metros: float
    tipo: str
    cluster: int
    segmento: str
    fecha: datetime

    class Config:
        from_attributes = True