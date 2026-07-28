from fastapi import APIRouter, UploadFile, File, Depends, HTTPException, Form
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from app.infrastructure.database.database import get_db
from app.infrastructure.security.dependencies import get_current_user
from app.infrastructure.database.models import User
import os
import uuid
import base64
import httpx
from typing import Optional

router = APIRouter()

UPLOAD_DIR = "/app/uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp", "image/jpg"}
MAX_SIZE_MB = 5

GOOGLE_VISION_API_KEY = os.getenv("GOOGLE_VISION_API_KEY")
VISION_URL = "https://vision.googleapis.com/v1/images:annotate"

# Niveles de SafeSearch que consideramos "no permitidos". Google regresa:
# UNKNOWN, VERY_UNLIKELY, UNLIKELY, POSSIBLE, LIKELY, VERY_LIKELY.
# Solo bloqueamos LIKELY/VERY_LIKELY para evitar falsos positivos con
# POSSIBLE (que es bastante común en fotos inocentes, ej. una alberca).
UNSAFE_LEVELS = {"LIKELY", "VERY_LIKELY"}

# Palabras esperadas en una foto de propiedad real, para el contexto
# "property". Si Vision no detecta NINGUNA de estas etiquetas, avisamos
# que la imagen no parece ser de una propiedad (advertencia suave, no
# bloqueo agresivo, porque las etiquetas de Vision son en inglés y
# genéricas, y una foto legítima pero muy cerrada podría no matchear).
PROPERTY_HINT_LABELS = {
    "house", "home", "building", "room", "apartment", "real estate",
    "property", "interior design", "furniture", "kitchen", "bedroom",
    "bathroom", "living room", "garden", "yard", "roof", "facade",
    "door", "window", "floor", "ceiling", "wall", "architecture",
    "residential area", "estate", "cottage", "villa", "condominium",
}


async def _call_vision_api(content: bytes, features: list) -> dict:
    b64 = base64.b64encode(content).decode("utf-8")
    payload = {
        "requests": [{
            "image": {"content": b64},
            "features": features,
        }]
    }
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.post(
            f"{VISION_URL}?key={GOOGLE_VISION_API_KEY}",
            json=payload,
        )
    resp.raise_for_status()
    data = resp.json()
    return data["responses"][0]


async def check_image_safety(content: bytes) -> Optional[str]:
    """
    Revisa contenido inapropiado (adulto, violento, sugerente) con
    SafeSearch. Regresa None si la imagen está bien, o el nombre de la
    categoría problemática si debe rechazarse.

    Si la API de Vision no está configurada o falla, se deja pasar la
    imagen (fail-open): preferimos no romper la subida de fotos por un
    problema de un servicio externo, a costa de no moderar en ese caso.
    """
    if not GOOGLE_VISION_API_KEY:
        return None
    try:
        result = await _call_vision_api(
            content, [{"type": "SAFE_SEARCH_DETECTION"}]
        )
        annotation = result.get("safeSearchAnnotation", {})
        for category in ("adult", "violence", "racy"):
            if annotation.get(category) in UNSAFE_LEVELS:
                return category
        return None
    except Exception:
        return None


async def check_looks_like_property(content: bytes) -> bool:
    """
    Heurística suave: revisa si alguna etiqueta detectada por Vision
    coincide con algo esperado en una foto de propiedad. Si Vision no
    está configurado o falla, se asume que sí (fail-open) — esto es una
    ayuda, no un filtro estricto, para no rechazar fotos legítimas por
    culpa de una etiqueta genérica.
    """
    if not GOOGLE_VISION_API_KEY:
        return True
    try:
        result = await _call_vision_api(
            content, [{"type": "LABEL_DETECTION", "maxResults": 15}]
        )
        labels = {
            label["description"].lower()
            for label in result.get("labelAnnotations", [])
        }
        return bool(labels & PROPERTY_HINT_LABELS)
    except Exception:
        return True


@router.post("/")
async def upload_file(
        file: UploadFile = File(...),
        context: Optional[str] = Form(None),
        current_user: User = Depends(get_current_user)
):
    """
    context: "property" para fotos de propiedades (aplica además la
    heurística de "parece una propiedad"), "profile" o cualquier otro
    valor/omitido para fotos de perfil (solo se aplica SafeSearch).
    """
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(status_code=400, detail="Solo se permiten imágenes JPG, PNG o WEBP")

    content = await file.read()
    if len(content) > MAX_SIZE_MB * 1024 * 1024:
        raise HTTPException(status_code=400, detail=f"El archivo no puede superar {MAX_SIZE_MB}MB")

    unsafe_category = await check_image_safety(content)
    if unsafe_category:
        raise HTTPException(
            status_code=400,
            detail="La imagen fue rechazada por contener contenido inapropiado. "
                   "Sube una foto distinta.",
        )

    if context == "property":
        looks_like_property = await check_looks_like_property(content)
        if not looks_like_property:
            raise HTTPException(
                status_code=400,
                detail="La imagen no parece ser de una propiedad (interior, "
                       "exterior o fachada). Sube una foto de la propiedad.",
            )

    ext = file.filename.split(".")[-1].lower()
    filename = f"{uuid.uuid4()}.{ext}"
    filepath = os.path.join(UPLOAD_DIR, filename)

    with open(filepath, "wb") as f:
        f.write(content)

    return {"url": f"/uploads/{filename}", "filename": filename}


@router.get("/{filename}")
async def get_file(filename: str):
    filepath = os.path.join(UPLOAD_DIR, filename)
    if not os.path.exists(filepath):
        raise HTTPException(status_code=404, detail="Archivo no encontrado")
    return FileResponse(filepath)