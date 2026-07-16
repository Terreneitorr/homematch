from fastapi import FastAPI, Request, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from app.infrastructure.database.database import Base, engine, get_db
from app.infrastructure.encryption import encryption

# Routers hexagonales
from app.adapters.inbound.auth_router import router as auth_router
from app.adapters.inbound.property_router import router as properties_router

# Routers existentes (pendientes de migración)
from app.users.router import router as users_router
from app.favorites.router import router as favorites_router
from app.history.router import router as history_router
from app.analytics.router import router as analytics_router
from app.appointments.router import router as appointments_router
from app.notifications.router import router as notifications_router
from app.uploads.router import router as uploads_router
from app.schedules.router import router as schedules_router
from app.chat.router import router as chat_router
from app.payments.router import router as payments_router
from app.profile.router import router as profile_router
from app.fcm.router import router as fcm_router
from app.infrastructure.fcm_service import init_firebase, is_firebase_initialized

# Adaptadores hexagonales
from app.adapters.outbound.postgres_property_repository import PostgresPropertyRepository
from app.adapters.outbound.ml_service_adapter import MLServiceAdapter
from app.core.use_cases.property_use_cases import (
    GetPropertiesUseCase, CreatePropertyUseCase, GetRecommendationsUseCase
)
from app.core.use_cases.payment_use_cases import CreatePaymentIntentUseCase
from app.adapters.outbound.stripe_payment_adapter import StripePaymentAdapter

# Inicializar Firebase al arrancar
init_firebase()
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="HomeMatch AI API",
    description="Plataforma inmobiliaria con arquitectura hexagonal",
    version="2.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
app.include_router(auth_router, prefix="/auth", tags=["Auth"])
app.include_router(users_router, prefix="/users", tags=["Users"])
app.include_router(properties_router, prefix="/properties", tags=["Properties"])
app.include_router(favorites_router, prefix="/favorites", tags=["Favorites"])
app.include_router(history_router, prefix="/history", tags=["History"])
app.include_router(analytics_router, prefix="/analytics", tags=["Analytics"])
app.include_router(appointments_router, prefix="/appointments", tags=["Appointments"])
app.include_router(notifications_router, prefix="/notifications", tags=["Notifications"])
app.include_router(uploads_router, prefix="/uploads", tags=["Uploads"])
app.include_router(schedules_router, prefix="/schedules", tags=["Schedules"])
app.include_router(chat_router, prefix="/chat", tags=["Chat"])
app.include_router(payments_router, prefix="/payments", tags=["Payments"])
app.include_router(profile_router, prefix="/profile", tags=["Profile"])
app.include_router(fcm_router, prefix="/fcm", tags=["FCM"])


# Endpoints hexagonales
@app.get("/v2/properties")
async def get_properties_v2(
        city: str = None,
        operation_type: str = None,
        min_price: float = None,
        max_price: float = None,
        db: Session = Depends(get_db)
):
    repo = PostgresPropertyRepository(db)
    use_case = GetPropertiesUseCase(repo)
    properties = await use_case.execute(
        city=city,
        operation_type=operation_type,
        min_price=min_price,
        max_price=max_price,
    )
    return [vars(p) for p in properties]


@app.post("/v2/encrypt")
async def encrypt_data(request: Request):
    body = await request.json()
    return {"encrypted": encryption.encrypt(body.get("data", ""))}


@app.post("/v2/decrypt")
async def decrypt_data(request: Request):
    body = await request.json()
    return {"data": encryption.decrypt(body.get("encrypted", ""))}


@app.get("/")
def root():
    return {
        "message": "HomeMatch AI API v2.0",
        "architecture": "Hexagonal (Ports & Adapters)",
        "firebase_initialized": is_firebase_initialized(),
        "docs": "/docs"
    }
