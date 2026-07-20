import joblib
import numpy as np
import os
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
from typing import List, Dict, Tuple, Optional

MODEL_PATH = "/app/model.pkl"
SCALER_PATH = "/app/scaler.pkl"
SEGMENT_MAP_PATH = "/app/segment_map.pkl"
USER_MODEL_PATH = "/app/user_model.pkl"
USER_SCALER_PATH = "/app/user_scaler.pkl"

# Nombres de segmento en orden ascendente de precio: el primero es el más
# barato, el último el más caro. El mapeo real cluster->nombre se calcula
# dinámicamente en train_property_model() según el precio promedio de cada
# cluster, NO según el número de cluster crudo que asigna K-Means (ese
# número es arbitrario y puede cambiar de orden en cada reentrenamiento).
ORDINAL_SEGMENT_NAMES = [
    "Departamento Económico",
    "Casa Familiar",
    "Residencia Premium",
    "Propiedad de Inversión",
]

TIPO_ENCODING = {
    "Casa": 0, "Departamento": 1,
    "Local": 2, "Terreno": 3, "Oficina": 4,
}


def encode_tipo(tipo: str) -> int:
    return TIPO_ENCODING.get(tipo, 0)


def get_segment_name(cluster: int) -> str:
    """
    Traduce un número de cluster crudo de K-Means a un nombre de segmento,
    usando el mapeo dinámico calculado en el último entrenamiento (guardado
    en SEGMENT_MAP_PATH). Si no existe (modelo nunca entrenado con el código
    nuevo), cae a un nombre genérico en vez de asumir un orden fijo incorrecto.
    """
    if os.path.exists(SEGMENT_MAP_PATH):
        segment_map = joblib.load(SEGMENT_MAP_PATH)
        if cluster in segment_map:
            return segment_map[cluster]
    return f"Segmento {cluster}"


def _build_segment_map(kmeans: KMeans, scaler: StandardScaler) -> Dict[int, str]:
    """
    Calcula qué número de cluster corresponde a qué nombre de segmento,
    ordenando los clusters por su precio promedio real (des-escalado),
    no por el índice crudo que les puso K-Means.
    """
    # cluster_centers_ está en espacio escalado; lo regresamos a escala
    # real para poder comparar precios de verdad entre clusters.
    centers_original_scale = scaler.inverse_transform(kmeans.cluster_centers_)
    # La columna 0 de las features es "precio" (ver el orden en
    # train_property_model: precio, habitaciones, banos, metros, tipo_encoded)
    avg_price_per_cluster = centers_original_scale[:, 0]

    # Índices de cluster ordenados de más barato a más caro
    clusters_sorted_by_price = np.argsort(avg_price_per_cluster)

    segment_map: Dict[int, str] = {}
    for rank, cluster_id in enumerate(clusters_sorted_by_price):
        name_index = min(rank, len(ORDINAL_SEGMENT_NAMES) - 1)
        segment_map[int(cluster_id)] = ORDINAL_SEGMENT_NAMES[name_index]

    return segment_map


def load_model() -> Tuple:
    if os.path.exists(MODEL_PATH) and os.path.exists(SCALER_PATH):
        return joblib.load(MODEL_PATH), joblib.load(SCALER_PATH)
    return None, None


def load_user_model() -> Tuple:
    if os.path.exists(USER_MODEL_PATH) and os.path.exists(USER_SCALER_PATH):
        return joblib.load(USER_MODEL_PATH), joblib.load(USER_SCALER_PATH)
    return None, None


def train_property_model(data: List[dict]) -> Tuple:
    df = pd.DataFrame(data)

    # Asegurar que existan las columnas necesarias
    if "tipo" not in df.columns:
        df["tipo"] = "Casa"
    if "precio" not in df.columns:
        return None, None

    df["tipo_encoded"] = df["tipo"].apply(encode_tipo)

    # Verificar columnas requeridas
    required = ["precio", "habitaciones", "banos", "metros"]
    for col in required:
        if col not in df.columns:
            df[col] = 0

    df = df.dropna(subset=required)
    df = df[df["precio"] > 0]

    if len(df) < 2:
        return None, None

    features = df[["precio", "habitaciones", "banos", "metros", "tipo_encoded"]].values

    scaler = StandardScaler()
    features_scaled = scaler.fit_transform(features)

    n = min(4, max(2, len(df) // 2))
    kmeans = KMeans(n_clusters=n, random_state=42, n_init=10)
    kmeans.fit(features_scaled)

    segment_map = _build_segment_map(kmeans, scaler)

    joblib.dump(kmeans, MODEL_PATH)
    joblib.dump(scaler, SCALER_PATH)
    joblib.dump(segment_map, SEGMENT_MAP_PATH)
    return kmeans, scaler


def classify_property(precio, habitaciones, banos, metros, tipo) -> Tuple[int, str]:
    """Clasifica una propiedad en un segmento usando K-Means."""
    model, scaler = load_model()
    if model is None:
        base_data = [
            {"precio": 450000, "habitaciones": 1, "banos": 1, "metros": 45, "tipo": "Departamento"},
            {"precio": 800000, "habitaciones": 2, "banos": 1, "metros": 65, "tipo": "Departamento"},
            {"precio": 1200000, "habitaciones": 2, "banos": 2, "metros": 80, "tipo": "Departamento"},
            {"precio": 1500000, "habitaciones": 3, "banos": 2, "metros": 120, "tipo": "Casa"},
            {"precio": 1850000, "habitaciones": 3, "banos": 2, "metros": 180, "tipo": "Casa"},
            {"precio": 2500000, "habitaciones": 4, "banos": 2, "metros": 220, "tipo": "Casa"},
            {"precio": 3200000, "habitaciones": 4, "banos": 3, "metros": 320, "tipo": "Casa"},
            {"precio": 4500000, "habitaciones": 5, "banos": 4, "metros": 450, "tipo": "Casa"},
        ]
        model, scaler = train_property_model(base_data)

    tipo_encoded = encode_tipo(tipo)
    features = np.array([[precio, habitaciones, banos, metros, tipo_encoded]])
    features_scaled = scaler.transform(features)
    cluster = int(model.predict(features_scaled)[0])
    return cluster, get_segment_name(cluster)


def build_user_vector(favorites: List[dict]) -> Optional[dict]:
    """
    Construye el vector de preferencias de un usuario basado en sus favoritos.

    Como dijo el profe: cada renglón es un usuario con sus características.
    Vector = [precio_promedio, hab_promedio, metros_promedio,
              num_favoritos, tipo_predominante]
    """
    if not favorites:
        return None

    precios = [f.get("price", 0) for f in favorites if f.get("price", 0) > 0]
    habs = [f.get("bedrooms", 0) for f in favorites]
    metros = [f.get("area", 0) for f in favorites if f.get("area", 0) > 0]

    # Tipo predominante (el que más aparece)
    tipos = []
    for f in favorites:
        title = f.get("title", "").lower()
        if "depto" in title or "departamento" in title or "apartamento" in title:
            tipos.append(1)
        elif "local" in title or "comercial" in title:
            tipos.append(2)
        elif "terreno" in title:
            tipos.append(3)
        else:
            tipos.append(0)  # Casa por default

    tipo_predominante = max(set(tipos), key=tipos.count) if tipos else 0

    if not precios:
        return None

    return {
        "avg_precio": np.mean(precios),
        "avg_habitaciones": np.mean(habs) if habs else 0,
        "avg_metros": np.mean(metros) if metros else 0,
        "num_favoritos": len(favorites),
        "tipo_predominante": tipo_predominante,
    }


def train_user_model(user_vectors: List[dict]) -> Tuple:
    """
    Entrena K-Means sobre USUARIOS para filtrado colaborativo.

    El profe explicó: de 10,000 usuarios hay 7 igualitos a ti,
    a ellos les preguntas y les recomiendas lo que a ellos les gustó.

    Cada fila = un usuario con sus preferencias promedio.
    K-Means agrupa usuarios similares en clusters.
    """
    if len(user_vectors) < 2:
        return None, None

    df = pd.DataFrame(user_vectors)
    features = df[[
        "avg_precio", "avg_habitaciones",
        "avg_metros", "num_favoritos", "tipo_predominante"
    ]].values

    scaler = StandardScaler()
    features_scaled = scaler.fit_transform(features)

    # Número óptimo de clusters — no más de la mitad de usuarios
    n_clusters = max(2, min(len(user_vectors) // 2, 8))
    kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
    kmeans.fit(features_scaled)

    joblib.dump(kmeans, USER_MODEL_PATH)
    joblib.dump(scaler, USER_SCALER_PATH)
    return kmeans, scaler


def get_collaborative_recommendations(
        current_user_favorites: List[dict],
        all_properties: List[dict],
        all_users_data: List[dict],
        limit: int = 6,
) -> List[dict]:
    """
    Filtrado Colaborativo — algoritmo correcto como explicó el profe:

    1. Construir vector del usuario actual (sus favoritos)
    2. Entrenar K-Means sobre TODOS los usuarios
    3. Encontrar en qué cluster cae el usuario actual
    4. Identificar usuarios del MISMO cluster (similares)
    5. Juntar los favoritos de esos usuarios similares
    6. Recomendar propiedades que NO tiene el usuario actual
    7. Ordenar por popularidad entre usuarios similares
    """
    my_fav_ids = {f.get("id") or f.get("property_id") for f in current_user_favorites}

    # Si no hay favoritos — retornar propiedades populares
    if not current_user_favorites:
        available = [p for p in all_properties if p.get("id") not in my_fav_ids]
        return available[:limit]

    # Construir vector del usuario actual
    current_vector = build_user_vector(current_user_favorites)
    if not current_vector:
        available = [p for p in all_properties if p.get("id") not in my_fav_ids]
        return available[:limit]

    # Si no hay datos de otros usuarios — usar similitud directa
    if not all_users_data or len(all_users_data) < 2:
        return _similarity_fallback(
            current_user_favorites, all_properties, my_fav_ids, limit
        )

    # Construir vectores de TODOS los usuarios
    user_vectors = []
    valid_users = []
    for user_data in all_users_data:
        vec = build_user_vector(user_data.get("favorites", []))
        if vec:
            user_vectors.append(vec)
            valid_users.append(user_data)

    # Agregar el usuario actual
    user_vectors.append(current_vector)

    if len(user_vectors) < 2:
        return _similarity_fallback(
            current_user_favorites, all_properties, my_fav_ids, limit
        )

    # Entrenar modelo de usuarios
    user_model, user_scaler = train_user_model(user_vectors)
    if not user_model:
        return _similarity_fallback(
            current_user_favorites, all_properties, my_fav_ids, limit
        )

    # Predecir cluster del usuario actual
    current_array = np.array([[
        current_vector["avg_precio"],
        current_vector["avg_habitaciones"],
        current_vector["avg_metros"],
        current_vector["num_favoritos"],
        current_vector["tipo_predominante"],
    ]])
    current_scaled = user_scaler.transform(current_array)
    my_cluster = int(user_model.predict(current_scaled)[0])

    # Encontrar usuarios del MISMO cluster (los "igualitos" del profe)
    similar_user_fav_ids = []
    for i, user_data in enumerate(valid_users):
        vec = user_vectors[i]
        arr = np.array([[
            vec["avg_precio"], vec["avg_habitaciones"],
            vec["avg_metros"], vec["num_favoritos"],
            vec["tipo_predominante"],
        ]])
        arr_scaled = user_scaler.transform(arr)
        cluster = int(user_model.predict(arr_scaled)[0])

        if cluster == my_cluster:
            # Este usuario es similar — tomar sus favoritos
            for fav in user_data.get("favorites", []):
                fav_id = fav.get("id") or fav.get("property_id")
                if fav_id and fav_id not in my_fav_ids:
                    similar_user_fav_ids.append(fav_id)

    # Contar popularidad de cada propiedad entre usuarios similares
    popularity: Dict[str, int] = {}
    for fav_id in similar_user_fav_ids:
        popularity[fav_id] = popularity.get(fav_id, 0) + 1

    # Ordenar por popularidad (más popular primero)
    sorted_prop_ids = sorted(
        popularity.keys(),
        key=lambda x: popularity[x],
        reverse=True
    )

    # Construir lista de propiedades recomendadas
    prop_map = {p["id"]: p for p in all_properties}
    recommendations = []
    for prop_id in sorted_prop_ids:
        if prop_id in prop_map and prop_id not in my_fav_ids:
            recommendations.append(prop_map[prop_id])
            if len(recommendations) >= limit:
                break

    # Completar con similitud si faltan
    if len(recommendations) < limit:
        fallback = _similarity_fallback(
            current_user_favorites, all_properties, my_fav_ids, limit
        )
        for p in fallback:
            if p not in recommendations:
                recommendations.append(p)
                if len(recommendations) >= limit:
                    break

    return recommendations


def _similarity_fallback(
        user_favorites: List[dict],
        all_properties: List[dict],
        my_fav_ids: set,
        limit: int,
) -> List[dict]:
    """
    Fallback: similitud directa por características cuando no hay
    suficientes usuarios para el filtrado colaborativo.
    """
    if not user_favorites:
        candidates = [p for p in all_properties if p.get("id") not in my_fav_ids]
        return candidates[:limit]

    precios = [f.get("price", 0) for f in user_favorites if f.get("price", 0) > 0]
    habs = [f.get("bedrooms", 0) for f in user_favorites]
    metros = [f.get("area", 0) for f in user_favorites if f.get("area", 0) > 0]

    avg_precio = np.mean(precios) if precios else 1000000
    avg_habs = np.mean(habs) if habs else 2
    avg_metros = np.mean(metros) if metros else 100

    candidates = [p for p in all_properties if p.get("id") not in my_fav_ids]

    def score(prop):
        p_diff = abs(prop.get("price", 0) - avg_precio) / (avg_precio + 1)
        h_diff = abs(prop.get("bedrooms", 0) - avg_habs) / (avg_habs + 1)
        m_diff = abs(prop.get("area", 0) - avg_metros) / (avg_metros + 1)
        return p_diff * 0.5 + h_diff * 0.3 + m_diff * 0.2

    candidates.sort(key=score)
    return candidates[:limit]