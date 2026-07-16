import httpx
import jwt
import os
from fastapi import FastAPI, Request, HTTPException, Depends, Response
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from cryptography.fernet import Fernet
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="HomeMatch AI Gateway", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Config
SECRET_KEY = os.getenv("SECRET_KEY", "supersecretkey123homematch")
ALGORITHM = "HS256"
BACKEND_URL = os.getenv("BACKEND_URL", "http://backend:8000")
ML_URL = os.getenv("ML_URL", "http://ml-service:8001")

# Key Manager — cifrado de datos sensibles
FERNET_KEY = os.getenv("FERNET_KEY") or Fernet.generate_key().decode()
fernet = Fernet(FERNET_KEY.encode() if isinstance(FERNET_KEY, str) else FERNET_KEY)

# Rutas públicas (sin auth)
PUBLIC_ROUTES = [
    ("/auth/login", "POST"),
    ("/auth/register", "POST"),
    ("/auth/google", "POST"),
    ("/properties/", "GET"),
    ("/properties", "GET"),
    ("/uploads/", "GET"),
    ("/ml/train-model", "POST"),      # Permitir entrenamiento sin token (mantenimiento)
    ("/ml/classify-property", "POST"), # Permitir clasificación sin token para rapidez
]

# Rutas que van al ML
ML_ROUTES = [
    "/ml/classify-property",
    "/ml/train-model",
    "/ml/inferences",
    "/ml/recommend",
]


class AuthChecker:
    """Valida JWT y extrae payload"""

    @staticmethod
    def validate_token(token: str) -> dict:
        try:
            payload = jwt.decode(
                token,
                SECRET_KEY,
                algorithms=[ALGORITHM]
            )
            return payload
        except jwt.ExpiredSignatureError:
            raise HTTPException(status_code=401, detail="Token expirado")
        except jwt.InvalidTokenError:
            raise HTTPException(status_code=401, detail="Token inválido")

    @staticmethod
    def extract_token(request: Request) -> str | None:
        auth = request.headers.get("Authorization", "")
        if auth.startswith("Bearer "):
            return auth[7:]
        return None


class KeyManager:
    """Gestiona cifrado/descifrado de datos sensibles"""

    @staticmethod
    def encrypt(data: str) -> str:
        return fernet.encrypt(data.encode()).decode()

    @staticmethod
    def decrypt(data: str) -> str:
        return fernet.decrypt(data.encode()).decode()

    @staticmethod
    def generate_api_key(user_id: str, role: str) -> str:
        """Genera clave temporal para servicios internos"""
        payload = {
            "sub": user_id,
            "role": role,
            "type": "internal",
        }
        return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


class Proxy:
    """Enruta requests al servicio correcto"""

    @staticmethod
    def get_target_url(path: str) -> str:
        # Rutas ML
        if path.startswith("/ml/"):
            clean_path = path[3:]  # quita /ml
            return f"{ML_URL}{clean_path}"
        # Todo lo demás va al backend
        return f"{BACKEND_URL}{path}"

    @staticmethod
    async def forward(
            request: Request,
            target_url: str,
            headers: dict,
            user_payload: dict | None = None,
    ) -> Response:
        try:
            body = await request.body()
        except:
            body = b""

        # Agregar headers de contexto del usuario
        forward_headers = {
            k: v for k, v in headers.items()
            if k.lower() not in ("host", "content-length")
        }

        if user_payload:
            forward_headers["X-User-Id"] = user_payload.get("sub", "")
            forward_headers["X-User-Role"] = user_payload.get("role", "")
            forward_headers["X-Gateway"] = "homematch-gateway"

        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.request(
                method=request.method,
                url=target_url,
                content=body,
                headers=forward_headers,
                params=dict(request.query_params),
            )

        # Manejar la respuesta
        content_type = response.headers.get("content-type", "")
        
        # Si es binario (imágenes), devolver Response crudo
        if "image/" in content_type or "application/octet-stream" in content_type:
            return Response(
                content=response.content,
                status_code=response.status_code,
                media_type=content_type
            )

        # Si es JSON, intentar parsear. Si falla, devolver texto crudo.
        try:
            return JSONResponse(
                content=response.json(),
                status_code=response.status_code,
            )
        except Exception as e:
            logger.error(f"[GATEWAY] Error parseando JSON: {e}")
            return Response(
                content=response.content,
                status_code=response.status_code,
                media_type=content_type or "text/plain"
            )


# ─── HEALTH CHECK ────────────────────────────────────────────────
@app.get("/health")
async def health():
    return {
        "status": "ok",
        "gateway": "HomeMatch AI Gateway v1.0",
        "services": {
            "backend": BACKEND_URL,
            "ml": ML_URL,
        }
    }


# ─── ENCRYPT ENDPOINT (para datos sensibles) ─────────────────────
@app.post("/gateway/encrypt")
async def encrypt_data(request: Request):
    body = await request.json()
    data = body.get("data", "")
    return {"encrypted": KeyManager.encrypt(data)}


@app.post("/gateway/decrypt")
async def decrypt_data(request: Request):
    body = await request.json()
    encrypted = body.get("encrypted", "")
    return {"data": KeyManager.decrypt(encrypted)}


# ─── PROXY PRINCIPAL ─────────────────────────────────────────────
@app.api_route(
    "/{path:path}",
    methods=["GET", "POST", "PUT", "DELETE", "PATCH"]
)
async def gateway_proxy(request: Request, path: str):
    full_path = f"/{path}"
    logger.info(f"[GATEWAY] {request.method} {full_path}")

    # Verificar si es ruta pública
    is_public = any(
        full_path.startswith(route) and
        (method == request.method or method == "*")
        for route, method in PUBLIC_ROUTES
    )

    user_payload = None

    if not is_public:
        # Auth Checker
        token = AuthChecker.extract_token(request)
        if not token:
            raise HTTPException(
                status_code=401,
                detail="Token de autorización requerido"
            )
        user_payload = AuthChecker.validate_token(token)

    # Proxy — determinar destino
    target_url = Proxy.get_target_url(full_path)
    logger.info(f"[PROXY] → {target_url}")

    return await Proxy.forward(
        request=request,
        target_url=target_url,
        headers=dict(request.headers),
        user_payload=user_payload,
    )
