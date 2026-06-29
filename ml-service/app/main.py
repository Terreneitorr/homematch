from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.router import router
from app.database import init_db

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

@app.on_event("startup")
def startup():
    init_db()

app.include_router(router, tags=["ML"])

@app.get("/")
def root():
    return {"message": "HomeMatch AI ML Service", "docs": "/docs"}