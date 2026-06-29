from sqlalchemy import create_engine, Column, String, Integer, Float, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.sql import func
import os

DATABASE_URL = os.getenv("ML_DATABASE_URL", "postgresql://homematch:homematch123@postgres:5432/homematch_db")

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class Inference(Base):
    __tablename__ = "inferences"
    id = Column(String, primary_key=True)
    precio = Column(Float)
    habitaciones = Column(Integer)
    banos = Column(Integer)
    metros = Column(Float)
    tipo = Column(String)
    cluster = Column(Integer)
    segmento = Column(String)
    fecha = Column(DateTime, server_default=func.now())

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    Base.metadata.create_all(bind=engine)