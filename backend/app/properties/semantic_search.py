"""
Búsqueda semántica híbrida para propiedades.

No usa embeddings pesados (sentence-transformers/torch) porque el plan
gratuito de Railway no aguanta esa carga. En su lugar combina:

1. Extracción de intención por palabras clave en español (precio,
   amenidades, zona) que se traduce en un "boost" de score sobre los
   campos estructurados que ya existen en el modelo (price, has_garden,
   has_garage, city, zone, colony).
2. TF-IDF + similitud coseno (scikit-learn) sobre title + description
   para capturar todo lo que no se resuelve con reglas.

No filtra "duro" (no descarta resultados): calcula un score por
propiedad y ordena de mayor a menor relevancia, para nunca devolver
una lista vacía si hay propiedades disponibles.
"""

import unicodedata
from typing import List

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity


# ---------------------------------------------------------------------
# Diccionarios de palabras clave (español, sin acentos ya normalizados
# se comparan después de quitarles los acentos con `_normalize`)
# ---------------------------------------------------------------------

PRICE_LOW_KEYWORDS = [
    "barata", "barato", "economica", "economico", "accesible",
    "asequible", "precio bajo", "low cost",
]

PRICE_HIGH_KEYWORDS = [
    "lujo", "lujosa", "lujoso", "exclusiva", "exclusivo", "premium",
    "cara", "caro", "alta gama", "residencial de lujo",
]

# keyword -> nombre del campo booleano en el modelo Property
AMENITY_KEYWORDS = {
    "has_garden": ["jardin", "jardines", "areas verdes", "patio verde"],
    "has_garage": ["cochera", "garage", "garaje", "estacionamiento"],
}

OPERATION_TYPE_KEYWORDS = {
    "rent": ["renta", "rentar", "en renta", "alquiler", "alquilar"],
    "sale": ["venta", "comprar", "en venta", "compra"],
}


def _normalize(text: str) -> str:
    """minúsculas + sin acentos, para matchear keywords de forma robusta."""
    text = text.lower().strip()
    text = unicodedata.normalize("NFKD", text)
    text = "".join(c for c in text if not unicodedata.combining(c))
    return text


def _contains_any(normalized_query: str, keywords: List[str]) -> bool:
    return any(_normalize(kw) in normalized_query for kw in keywords)


def _price_percentile_score(price: float, prices: List[float], favor_low: bool) -> float:
    """
    Devuelve un score 0..1 según qué tan barata/cara es una propiedad
    respecto al resto del set. favor_low=True premia precios bajos.
    """
    if not prices or price is None:
        return 0.0
    sorted_prices = sorted(prices)
    n = len(sorted_prices)
    if n == 1:
        return 0.5
    # posición relativa del precio dentro del rango (0 = más barata, 1 = más cara)
    rank = sum(1 for p in sorted_prices if p <= price) / n
    return (1 - rank) if favor_low else rank


def parse_query(query: str) -> dict:
    """Extrae intención estructurada de una búsqueda en texto libre."""
    normalized = _normalize(query)

    price_hint = None
    if _contains_any(normalized, PRICE_LOW_KEYWORDS):
        price_hint = "low"
    elif _contains_any(normalized, PRICE_HIGH_KEYWORDS):
        price_hint = "high"

    amenities_matched = [
        field for field, keywords in AMENITY_KEYWORDS.items()
        if _contains_any(normalized, keywords)
    ]

    operation_type_hint = None
    for op_type, keywords in OPERATION_TYPE_KEYWORDS.items():
        if _contains_any(normalized, keywords):
            operation_type_hint = op_type
            break

    return {
        "price_hint": price_hint,
        "amenities": amenities_matched,
        "operation_type_hint": operation_type_hint,
        "normalized_query": normalized,
    }


def semantic_search(query: str, properties: list, top_n: int = 10) -> list:
    """
    Recibe la lista de objetos Property (ya cargados desde la BD) y el
    query en texto libre del usuario. Devuelve la misma lista de
    Property, ordenada de más a menos relevante, recortada a top_n.
    """
    if not properties:
        return []

    if not query or not query.strip():
        # sin query, no hay nada que rankear semánticamente
        return properties[:top_n]

    intent = parse_query(query)

    # Precios agrupados por operation_type: comparar renta vs venta en el
    # mismo percentil no tiene sentido (escalas totalmente distintas).
    prices_by_op_type: dict = {}
    for p in properties:
        if p.price is None:
            continue
        op_type = getattr(p.operation_type, "value", p.operation_type)
        prices_by_op_type.setdefault(op_type, []).append(p.price)

    # --- TF-IDF sobre title + description ---
    corpus = [f"{p.title or ''} {p.description or ''}" for p in properties]
    corpus.append(query)  # el query va al final como "documento" extra

    tfidf_scores = [0.0] * len(properties)
    try:
        vectorizer = TfidfVectorizer(strip_accents="unicode", lowercase=True)
        tfidf_matrix = vectorizer.fit_transform(corpus)
        query_vector = tfidf_matrix[-1]
        property_vectors = tfidf_matrix[:-1]
        similarities = cosine_similarity(query_vector, property_vectors)[0]
        tfidf_scores = similarities.tolist()
    except ValueError:
        # corpus vacío o solo stopwords, se ignora TF-IDF y se sigue con reglas
        pass

    scored = []
    for prop, tfidf_score in zip(properties, tfidf_scores):
        score = tfidf_score * 3.0  # peso del match semántico de texto

        if intent["price_hint"] in ("low", "high"):
            prop_op_type = getattr(prop.operation_type, "value", prop.operation_type)
            comparable_prices = prices_by_op_type.get(prop_op_type, [])
            favor_low = intent["price_hint"] == "low"
            score += _price_percentile_score(prop.price, comparable_prices, favor_low) * 2.0

        for amenity_field in intent["amenities"]:
            if getattr(prop, amenity_field, False):
                score += 2.0

        if intent["operation_type_hint"]:
            prop_op_type = getattr(prop.operation_type, "value", prop.operation_type)
            if prop_op_type == intent["operation_type_hint"]:
                score += 1.5

        zone_text = _normalize(
            f"{prop.city or ''} {prop.zone or ''} {prop.colony or ''}"
        )
        query_words = intent["normalized_query"].split()
        if any(word in zone_text for word in query_words if len(word) > 3):
            score += 2.0

        scored.append((score, prop))

    scored.sort(key=lambda pair: pair[0], reverse=True)
    return [prop for _, prop in scored[:top_n]]