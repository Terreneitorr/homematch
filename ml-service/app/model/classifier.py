import joblib
import numpy as np
import os
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
import pandas as pd

MODEL_PATH = "/app/model.pkl"
SCALER_PATH = "/app/scaler.pkl"

SEGMENT_NAMES = {
    0: "Departamento Económico",
    1: "Casa Familiar",
    2: "Residencia Premium",
    3: "Propiedad de Inversión",
}

TIPO_ENCODING = {
    "Casa": 0,
    "Departamento": 1,
    "Local": 2,
    "Terreno": 3,
    "Oficina": 4,
}

def get_segment_name(cluster: int) -> str:
    return SEGMENT_NAMES.get(cluster, f"Segmento {cluster}")

def encode_tipo(tipo: str) -> int:
    return TIPO_ENCODING.get(tipo, 0)

def load_model():
    if os.path.exists(MODEL_PATH) and os.path.exists(SCALER_PATH):
        model = joblib.load(MODEL_PATH)
        scaler = joblib.load(SCALER_PATH)
        return model, scaler
    return None, None

def train_model(data: list[dict]):
    df = pd.DataFrame(data)
    df["tipo_encoded"] = df["tipo"].apply(encode_tipo)

    features = df[["precio", "habitaciones", "banos", "metros", "tipo_encoded"]].values

    scaler = StandardScaler()
    features_scaled = scaler.fit_transform(features)

    # Método del codo simplificado — usamos 4 clusters
    kmeans = KMeans(n_clusters=4, random_state=42, n_init=10)
    kmeans.fit(features_scaled)

    joblib.dump(kmeans, MODEL_PATH)
    joblib.dump(scaler, SCALER_PATH)

    return kmeans, scaler

def classify_property(precio: float, habitaciones: int, banos: int, metros: float, tipo: str):
    model, scaler = load_model()

    if model is None:
        # Si no hay modelo entrenado, entrenar con datos de ejemplo
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
        model, scaler = train_model(sample_data)

    tipo_encoded = encode_tipo(tipo)
    features = np.array([[precio, habitaciones, banos, metros, tipo_encoded]])
    features_scaled = scaler.transform(features)
    cluster = int(model.predict(features_scaled)[0])
    segmento = get_segment_name(cluster)

    return cluster, segmento