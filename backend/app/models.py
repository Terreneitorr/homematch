from sqlalchemy import Column, String, Float, Integer, Boolean, DateTime, Enum, ForeignKey, Text, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import enum
from datetime import datetime

class UserRole(str, enum.Enum):
    USER = "USER"
    SELLER = "SELLER"
    AGENCY = "AGENCY"
    ADMIN = "ADMIN"

class OperationType(str, enum.Enum):
    sale = "sale"
    rent = "rent"

class PropertyStatus(str, enum.Enum):
    available = "available"
    reserved = "reserved"
    sold = "sold"
    rented = "rented"
    inactive = "inactive"

class User(Base):
    __tablename__ = "users"
    id = Column(String, primary_key=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False)
    password_hash = Column(String, nullable=True)
    role = Column(Enum(UserRole), default=UserRole.USER)
    avatar = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    accepted_terms = Column(Boolean, default=False)
    created_at = Column(DateTime, server_default=func.now())

    properties = relationship("Property", back_populates="owner")
    favorites = relationship("Favorite", back_populates="user")
    history = relationship("SearchHistory", back_populates="user")

class Property(Base):
    __tablename__ = "properties"
    id = Column(String, primary_key=True)
    owner_id = Column(String, ForeignKey("users.id"))
    title = Column(String, nullable=False)
    description = Column(Text, nullable=False)
    price = Column(Float, nullable=False)
    operation_type = Column(Enum(OperationType), nullable=False)
    status = Column(Enum(PropertyStatus), default=PropertyStatus.available)
    city = Column(String, nullable=False)
    zone = Column(String, nullable=False)
    colony = Column(String, nullable=True)
    bedrooms = Column(Integer, default=1)
    bathrooms = Column(Integer, default=1)
    has_garage = Column(Boolean, default=False)
    has_garden = Column(Boolean, default=False)
    area = Column(Float, nullable=False)
    photos = Column(JSON, default=list)
    cluster = Column(Integer, nullable=True)
    created_at = Column(DateTime, server_default=func.now())

    owner = relationship("User", back_populates="properties")
    favorites = relationship("Favorite", back_populates="property")

class Favorite(Base):
    __tablename__ = "favorites"
    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.id"))
    property_id = Column(String, ForeignKey("properties.id"))
    saved_at = Column(DateTime, server_default=func.now())

    user = relationship("User", back_populates="favorites")
    property = relationship("Property", back_populates="favorites")

class SearchHistory(Base):
    __tablename__ = "search_history"
    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.id"))
    query = Column(String, nullable=False)
    searched_at = Column(DateTime, server_default=func.now())

    user = relationship("User", back_populates="history")

class AppointmentType(str, enum.Enum):
    presencial = "presencial"
    virtual = "virtual"
    telefonica = "telefonica"

class AppointmentStatus(str, enum.Enum):
    pendiente = "pendiente"
    confirmada = "confirmada"
    cancelada = "cancelada"
    rechazada = "rechazada"
    reagendada = "reagendada"

class Appointment(Base):
    __tablename__ = "appointments"
    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    seller_id = Column(String, nullable=False)
    property_id = Column(String, ForeignKey("properties.id"), nullable=False)
    appointment_type = Column(
        Enum(AppointmentType), default=AppointmentType.presencial)
    status = Column(
        Enum(AppointmentStatus), default=AppointmentStatus.pendiente)
    scheduled_at = Column(DateTime, nullable=False)
    notes = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class SellerSchedule(Base):
    __tablename__ = "seller_schedules"
    id = Column(String, primary_key=True)
    seller_id = Column(String, ForeignKey("users.id"), unique=True)
    monday = Column(Boolean, default=True)
    tuesday = Column(Boolean, default=True)
    wednesday = Column(Boolean, default=True)
    thursday = Column(Boolean, default=True)
    friday = Column(Boolean, default=True)
    saturday = Column(Boolean, default=False)
    sunday = Column(Boolean, default=False)
    start_hour = Column(Integer, default=9)
    end_hour = Column(Integer, default=18)
    slot_duration = Column(Integer, default=60)


class Conversation(Base):
    __tablename__ = "conversations"
    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    seller_id = Column(String, ForeignKey("users.id"), nullable=False)
    property_id = Column(String, ForeignKey("properties.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    last_message_at = Column(DateTime, default=datetime.utcnow)


class Message(Base):
    __tablename__ = "messages"
    id = Column(String, primary_key=True)
    conversation_id = Column(String, ForeignKey("conversations.id"), nullable=False)
    sender_id = Column(String, ForeignKey("users.id"), nullable=False)
    content = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
