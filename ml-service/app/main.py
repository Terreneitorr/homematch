from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.router import router
from app.database import init_db, get_db, Inference
from app.model.classifier import load_model, train_property_model

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

# Datos base de respaldo, solo se usan si no hay NADA en la base de datos
# todavía (por ejemplo, un despliegue completamente nuevo).
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


def _load_real_training_data():
    """Intenta juntar datos reales de la tabla Inference para entrenar."""
    try:
        db = next(get_db())
        try:
            inferences = db.query(Inference).all()
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
            return data
        finally:
            db.close()
    except Exception as e:
        print(f"[startup] No se pudieron leer datos reales: {e}")
        return []


@app.on_event("startup")
def startup():
    init_db()

    # Si el modelo no existe en disco (nunca se entrenó, o se perdió por un
    # redeploy en disco efímero), lo entrenamos automáticamente.
    model, scaler = load_model()
    if model is None:
        print("[startup] No hay modelo entrenado, buscando datos reales...")
        real_data = _load_real_training_data()

        if len(real_data) >= 10:
            print(f"[startup] Entrenando con {len(real_data)} clasificaciones reales de la BD.")
            train_property_model(real_data)
        else:
            print("[startup] No hay suficientes datos reales, usando datos base.")
            train_property_model(BASE_TRAINING_DATA)

        print("[startup] Modelo entrenado correctamente.")


app.include_router(router, tags=["ML"])


@app.get("/")
def root():
    return {"message": "HomeMatch AI ML Service", "docs": "/docs"}