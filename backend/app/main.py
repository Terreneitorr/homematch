from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import Base, engine
from app.auth.router import router as auth_router
from app.properties.router import router as properties_router
from app.favorites.router import router as favorites_router
from app.history.router import router as history_router
from app.analytics.router import router as analytics_router
from app.profile.router import router as profile_router
from app.appointments.router import router as appointments_router
from app.appointments.router import Appointment  # importa el modelo
from app.users.router import router as users_router
from app.uploads.router import router as uploads_router
from app.notifications.router import router as notifications_router, Notification
from app.schedules.router import router as schedules_router
from app.chat.router import router as chat_router
from app.payments.router import router as payments_router




Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="HomeMatch AI API",
    description="API REST para la plataforma inmobiliaria HomeMatch AI",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/auth", tags=["Auth"])
app.include_router(properties_router, prefix="/properties", tags=["Properties"])
app.include_router(favorites_router, prefix="/favorites", tags=["Favorites"])
app.include_router(history_router, prefix="/history", tags=["History"])
app.include_router(analytics_router, prefix="/analytics", tags=["Analytics"])
app.include_router(profile_router, prefix="/profile", tags=["Profile"])
app.include_router(appointments_router, prefix="/appointments", tags=["Appointments"])
app.include_router(users_router, prefix="/users", tags=["Users"])
app.include_router(uploads_router, prefix="/uploads", tags=["Uploads"])
app.include_router(notifications_router, prefix="/notifications", tags=["Notifications"])
app.include_router(schedules_router, prefix="/schedules", tags=["Schedules"])
app.include_router(chat_router, prefix="/chat", tags=["Chat"])
app.include_router(payments_router, prefix="/payments", tags=["Payments"])


@app.get("/")
def root():
    return {"message": "HomeMatch AI API funcionando", "docs": "/docs"}