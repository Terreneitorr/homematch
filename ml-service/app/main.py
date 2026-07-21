from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.router import router
from app.database import init_db
from app.model.classifier import load_model, train_property_model
import os

app = FastAPI(
    title="HomeMatch AI - ML Service",
    description="Microservicio de Machine Learning para clasificación de propiedades con K-Means",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Datos base de respaldo, por si el modelo se pierde (Railway usa disco
# efímero: si el contenedor se redespliega, model.pkl/segment_map.pkl
# desaparecen) y no hay suficientes datos reales todavía en la BD.
BASE_TRAINING_DATA = [
    {"precio": 450000, "habitaciones": 1, "banos": 1, "metros": 45, "tipo": "Departamento"},
    {"precio": 800000, "habitaciones": 2, "banos": 1, "metros": 65, "tipo": "Departamento"},
    {"precio": 1200000, "habitaciones": 2, "banos": 2, "metros": 80, "tipo": "Departamento"},
    {"precio": 1500000, "habitaciones": 3, "banos": 2, "metros": 120, "tipo": "Casa"},
    {"precio": 1850000, "habitaciones": 3, "banos": 2, "metros": 180, "tipo": "Casa"},
    {"precio": 2500000, "habitaciones": 4, "banos": 2, "metros": 220, "tipo": "Casa"},
    {"precio": 3200000, "habitaciones": 4, "banos": 3, "metros": 320, "tipo": "Casa"},
    {"precio": 4500000, "habitaciones": 5, "banos": 4, "metros": 450, "tipo": "Casa"},
]


@app.on_event("startup")
def startup():
    init_db()

    # Si el modelo no existe en disco (nunca se entrenó, o se perdió por un
    # redeploy en disco efímero), lo entrenamos automáticamente con datos
    # base para que el servicio nunca quede "roto" esperando una llamada
    # manual a /train-model.
    model, scaler = load_model()
    if model is None:
        print("[startup] No hay modelo entrenado, entrenando con datos base...")
        train_property_model(BASE_TRAINING_DATA)
        print("[startup] Modelo base entrenado correctamente.")


app.include_router(router, tags=["ML"])


@app.get("/")
def root():
    return {"message": "HomeMatch AI ML Service", "docs": "/docs"}