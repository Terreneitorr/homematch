import joblib
import numpy as np
import os
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import silhouette_score
from typing import List, Tuple

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


def encode_tipo(tipo: str) -> int:
    return TIPO_ENCODING.get(tipo, 0)


def get_segment_name(cluster: int) -> str:
    return SEGMENT_NAMES.get(cluster, f"Segmento {cluster}")


def load_model() -> Tuple[KMeans | None, StandardScaler | None]:
    if os.path.exists(MODEL_PATH) and os.path.exists(SCALER_PATH):
        return joblib.load(MODEL_PATH), joblib.load(SCALER_PATH)
    return None, None


def find_optimal_clusters(features_scaled: np.ndarray, max_k: int = 6) -> int:
    """Encuentra el número óptimo de clusters con el método del codo"""
    if len(features_scaled) < 4:
        return 2

    inertias = []
    k_range = range(2, min(max_k + 1, len(features_scaled)))

    for k in k_range:
        km = KMeans(n_clusters=k, random_state=42, n_init=10)
        km.fit(features_scaled)
        inertias.append(km.inertia_)

    # Método del codo — encontrar el punto de inflexión
    if len(inertias) < 2:
        return 2

    diffs = [inertias[i] - inertias[i + 1] for i in range(len(inertias) - 1)]
    optimal_idx = diffs.index(max(diffs))
    return list(k_range)[optimal_idx]


def train_model(data: List[dict]) -> Tuple[KMeans, StandardScaler]:
    """Entrena el modelo con datos reales"""
    if not data:
        # Si no hay datos, usar datos de ejemplo iniciales
        data = [
            {"precio": 500000, "habitaciones": 1, "banos": 1, "metros": 40, "tipo": "Departamento"},
            {"precio": 1200000, "habitaciones": 2, "banos": 1, "metros": 70, "tipo": "Departamento"},
            {"precio": 1850000, "habitaciones": 3, "banos": 2, "metros": 180, "tipo": "Casa"},
            {"precio": 3200000, "habitaciones": 4, "banos": 3, "metros": 320, "tipo": "Casa"},
        ]

    df = pd.DataFrame(data)

    required = ["precio", "habitaciones", "banos", "metros", "tipo"]
    for col in required:
        if col not in df.columns:
            # Si faltan columnas, intentar completar con valores por defecto o fallar
            if len(df) == 0:
                return train_model([]) # Recursión segura con lista vacía manejada arriba
            raise ValueError(f"Columna requerida: {col}")

    df["tipo_encoded"] = df["tipo"].apply(encode_tipo)
    df = df.dropna(subset=["precio", "habitaciones", "banos", "metros"])
    df = df[df["precio"] > 0]
    df = df[df["metros"] > 0]

    if len(df) < 4:
        # Datos insuficientes — agregar datos de ejemplo
        sample = [
            {"precio": 500000, "habitaciones": 1, "banos": 1, "metros": 40, "tipo_encoded": 1},
            {"precio": 1200000, "habitaciones": 2, "banos": 1, "metros": 70, "tipo_encoded": 1},
            {"precio": 1850000, "habitaciones": 3, "banos": 2, "metros": 180, "tipo_encoded": 0},
            {"precio": 3200000, "habitaciones": 4, "banos": 3, "metros": 320, "tipo_encoded": 0},
        ]
        df_sample = pd.DataFrame(sample)
        df = pd.concat([df[["precio", "habitaciones", "banos", "metros", "tipo_encoded"]], df_sample])

    features = df[["precio", "habitaciones", "banos", "metros", "tipo_encoded"]].values

    scaler = StandardScaler()
    features_scaled = scaler.fit_transform(features)

    # Número óptimo de clusters
    n_clusters = find_optimal_clusters(features_scaled)
    n_clusters = min(n_clusters, 4)  # máximo 4 segmentos

    kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
    kmeans.fit(features_scaled)

    # Calcular score
    if len(features_scaled) > n_clusters:
        score = silhouette_score(features_scaled, kmeans.labels_)
        print(f"[ML] Modelo entrenado: {n_clusters} clusters, silhouette={score:.3f}")

    joblib.dump(kmeans, MODEL_PATH)
    joblib.dump(scaler, SCALER_PATH)

    return kmeans, scaler


def classify_property(
        precio: float,
        habitaciones: int,
        banos: int,
        metros: float,
        tipo: str,
) -> Tuple[int, str]:
    model, scaler = load_model()

    if model is None:
        # Auto-entrenar con datos de ejemplo
        sample = [
            {"precio": 500000, "habitaciones": 1, "banos": 1, "metros": 40, "tipo": "Departamento"},
            {"precio": 800000, "habitaciones": 2, "banos": 1, "metros": 65, "tipo": "Departamento"},
            {"precio": 1200000, "habitaciones": 2, "banos": 2, "metros": 80, "tipo": "Departamento"},
            {"precio": 1500000, "habitaciones": 3, "banos": 2, "metros": 120, "tipo": "Casa"},
            {"precio": 1850000, "habitaciones": 3, "banos": 2, "metros": 180, "tipo": "Casa"},
            {"precio": 2500000, "habitaciones": 4, "banos": 2, "metros": 220, "tipo": "Casa"},
            {"precio": 3200000, "habitaciones": 4, "banos": 3, "metros": 320, "tipo": "Casa"},
            {"precio": 5000000, "habitaciones": 5, "banos": 4, "metros": 500, "tipo": "Casa"},
            {"precio": 700000, "habitaciones": 1, "banos": 1, "metros": 35, "tipo": "Departamento"},
            {"precio": 950000, "habitaciones": 2, "banos": 1, "metros": 55, "tipo": "Departamento"},
        ]
        model, scaler = train_model(sample)

    tipo_encoded = encode_tipo(tipo)
    features = np.array([[precio, habitaciones, banos, metros, tipo_encoded]])
    features_scaled = scaler.transform(features)
    cluster = int(model.predict(features_scaled)[0])
    segmento = get_segment_name(cluster)

    return cluster, segmento