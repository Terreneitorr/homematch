import joblib
import numpy as np
import os
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
from typing import List, Tuple, Dict

MODEL_PATH = "/app/model.pkl"
SCALER_PATH = "/app/scaler.pkl"
USER_MODEL_PATH = "/app/user_model.pkl"
USER_SCALER_PATH = "/app/user_scaler.pkl"

SEGMENT_NAMES = {
    0: "Departamento Económico",
    1: "Casa Familiar",
    2: "Residencia Premium",
    3: "Propiedad de Inversión",
}

TIPO_ENCODING = {
    "Casa": 0, "Departamento": 1,
    "Local": 2, "Terreno": 3, "Oficina": 4,
}


def encode_tipo(tipo: str) -> int:
    return TIPO_ENCODING.get(tipo, 0)


def get_segment_name(cluster: int) -> str:
    return SEGMENT_NAMES.get(cluster, f"Segmento {cluster}")


def load_model() -> Tuple:
    if os.path.exists(MODEL_PATH) and os.path.exists(SCALER_PATH):
        return joblib.load(MODEL_PATH), joblib.load(SCALER_PATH)
    return None, None


def load_user_model() -> Tuple:
    if os.path.exists(USER_MODEL_PATH) and os.path.exists(USER_SCALER_PATH):
        return joblib.load(USER_MODEL_PATH), joblib.load(USER_SCALER_PATH)
    return None, None


def train_property_model(data: List[dict]):
    """Entrena K-Means sobre propiedades para clasificarlas en segmentos"""
    df = pd.DataFrame(data)
    df["tipo_encoded"] = df["tipo"].apply(encode_tipo)
    features = df[["precio", "habitaciones", "banos",
                   "metros", "tipo_encoded"]].values

    scaler = StandardScaler()
    features_scaled = scaler.fit_transform(features)

    n = min(4, max(2, len(df) // 3))
    kmeans = KMeans(n_clusters=n, random_state=42, n_init=10)
    kmeans.fit(features_scaled)

    joblib.dump(kmeans, MODEL_PATH)
    joblib.dump(scaler, SCALER_PATH)
    return kmeans, scaler


def train_user_model(user_vectors: List[dict]):
    """
    Entrena K-Means sobre USUARIOS para filtrado colaborativo.

    Cada usuario es un vector de sus preferencias:
    [precio_promedio_favoritos, hab_promedio, metros_promedio,
     num_favoritos, tipo_predominante]

    El profe dijo: encuentra usuarios igualitos a ti →
    recomiéndales lo que a ellos les gustó
    """
    if len(user_vectors) < 3:
        return None, None

    df = pd.DataFrame(user_vectors)
    features = df[[
        "avg_precio", "avg_habitaciones",
        "avg_metros", "num_favoritos", "tipo_predominante"
    ]].values

    scaler = StandardScaler()
    features_scaled = scaler.fit_transform(features)

    # Número de clusters = raíz cuadrada de usuarios (regla práctica)
    n_clusters = min(max(2, int(np.sqrt(len(df)))), 8)
    kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
    kmeans.fit(features_scaled)

    joblib.dump(kmeans, USER_MODEL_PATH)
    joblib.dump(scaler, USER_SCALER_PATH)
    return kmeans, scaler


def classify_property(precio, habitaciones, banos, metros, tipo):
    """Clasifica una propiedad en un segmento"""
    model, scaler = load_model()
    if model is None:
        # Auto-entrenar con datos base
        base_data = [
            {"precio": 500000, "habitaciones": 1, "banos": 1, "metros": 40, "tipo": "Departamento"},
            {"precio": 800000, "habitaciones": 2, "banos": 1, "metros": 65, "tipo": "Departamento"},
            {"precio": 1200000, "habitaciones": 2, "banos": 2, "metros": 80, "tipo": "Departamento"},
            {"precio": 1500000, "habitaciones": 3, "banos": 2, "metros": 120, "tipo": "Casa"},
            {"precio": 1850000, "habitaciones": 3, "banos": 2, "metros": 180, "tipo": "Casa"},
            {"precio": 2500000, "habitaciones": 4, "banos": 2, "metros": 220, "tipo": "Casa"},
            {"precio": 3200000, "habitaciones": 4, "banos": 3, "metros": 320, "tipo": "Casa"},
            {"precio": 5000000, "habitaciones": 5, "banos": 4, "metros": 500, "tipo": "Casa"},
        ]
        model, scaler = train_property_model(base_data)

    tipo_encoded = encode_tipo(tipo)
    features = np.array([[precio, habitaciones, banos, metros, tipo_encoded]])
    features_scaled = scaler.transform(features)
    cluster = int(model.predict(features_scaled)[0])
    return cluster, get_segment_name(cluster)


def get_collaborative_recommendations(
        user_favorites: List[dict],
        all_properties: List[dict],
        all_users_favorites: List[dict],
        limit: int = 6,
) -> List[dict]:
    """
    Filtrado colaborativo — el algoritmo del profe:

    1. Crear vector del usuario actual con sus favoritos
    2. Encontrar usuarios similares (mismo cluster)
    3. Recomendar lo que a esos usuarios similares les gustó
    4. Excluir lo que el usuario ya tiene en favoritos
    """
    if not user_favorites or not all_users_favorites:
        # Sin datos suficientes → devolver propiedades populares
        return all_properties[:limit]

    # Vector del usuario actual
    current_vector = _build_user_vector(user_favorites)
    if current_vector is None:
        return all_properties[:limit]

    # Cargar modelo de usuarios
    user_model, user_scaler = load_user_model()

    if user_model is None:
        # Entrenar con todos los usuarios disponibles
        all_vectors = [
            v for v in [
                _build_user_vector(favs)
                for favs in all_users_favorites
            ] if v is not None
        ]
        if len(all_vectors) < 3:
            return all_properties[:limit]
        user_model, user_scaler = train_user_model(all_vectors)

    # Encontrar cluster del usuario actual
    current_array = np.array([[
        current_vector["avg_precio"],
        current_vector["avg_habitaciones"],
        current_vector["avg_metros"],
        current_vector["num_favoritos"],
        current_vector["tipo_predominante"],
    ]])
    current_scaled = user_scaler.transform(current_array)
    user_cluster = int(user_model.predict(current_scaled)[0])

    # IDs de favoritos actuales (para excluir)
    my_fav_ids = {f["id"] for f in user_favorites}

    # Propiedades que le gustaron a usuarios del mismo cluster
    # (usuarios similares)
    similar_user_favs = []
    for user_favs in all_users_favorites:
        vec = _build_user_vector(user_favs)
        if vec is None:
            continue
        arr = np.array([[
            vec["avg_precio"], vec["avg_habitaciones"],
            vec["avg_metros"], vec["num_favoritos"],
            vec["tipo_predominante"],
        ]])
        arr_scaled = user_scaler.transform(arr)
        cluster = int(user_model.predict(arr_scaled)[0])
        if cluster == user_cluster:
            similar_user_favs.extend(user_favs)

    # Propiedades más populares entre usuarios similares
    # que el usuario actual NO tiene en favoritos
    prop_scores: Dict[str, float] = {}
    for fav in similar_user_favs:
        if fav["id"] not in my_fav_ids:
            prop_scores[fav["id"]] = prop_scores.get(fav["id"], 0) + 1

    # Ordenar por popularidad entre usuarios similares
    sorted_ids = sorted(
        prop_scores.keys(),
        key=lambda x: prop_scores[x],
        reverse=True
    )

    # Devolver propiedades ordenadas
    result = []
    prop_map = {p["id"]: p for p in all_properties}
    for pid in sorted_ids[:limit]:
        if pid in prop_map:
            result.append(prop_map[pid])

    # Si no hay suficientes → completar con propiedades del segmento similar
    if len(result) < limit:
        for prop in all_properties:
            if prop["id"] not in my_fav_ids and prop not in result:
                result.append(prop)
                if len(result) >= limit:
                    break

    return result


def _build_user_vector(favorites: List[dict]):
    """Construye el vector de preferencias de un usuario"""
    if not favorites:
        return None

    precios = [f.get("price", 0) for f in favorites if f.get("price")]
    habs = [f.get("bedrooms", 0) for f in favorites]
    metros = [f.get("area", 0) for f in favorites if f.get("area")]
    tipos = [encode_tipo(f.get("tipo", "Casa")) for f in favorites]

    if not precios:
        return None

    return {
        "avg_precio": np.mean(precios),
        "avg_habitaciones": np.mean(habs),
        "avg_metros": np.mean(metros) if metros else 0,
        "num_favoritos": len(favorites),
        "tipo_predominante": max(set(tipos), key=tipos.count),
    }