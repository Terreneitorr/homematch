from sqlalchemy import Column, String, Float, Boolean, Integer, DateTime, ForeignKey, Text, JSON
from sqlalchemy.orm import relationship
from .database import Base
import datetime
import enum

class UserRole(str, enum.Enum):
    USER = "USER"
    SELLER = "SELLER"
    AGENCY = "AGENCY"
    ADMIN = "ADMIN"

class PropertyStatus(str, enum.Enum):
    available = "available"
    reserved = "reserved"
    sold = "sold"
    rented = "rented"

class OperationType(str, enum.Enum):
    sale = "sale"
    rent = "rent"

class AppointmentStatus(str, enum.Enum):
    pendiente = "pendiente"
    confirmada = "confirmada"
    rechazada = "rechazada"
    cancelada = "cancelada"
    reagendada = "reagendada"

class User(Base):
    __tablename__ = "users"
    id = Column(String, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    password_hash = Column(String)
    name = Column(String)
    role = Column(String, default="USER")
    avatar = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    accepted_terms = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    properties = relationship("Property", back_populates="owner")

class Property(Base):
    __tablename__ = "properties"
    id = Column(String, primary_key=True, index=True)
    owner_id = Column(String, ForeignKey("users.id"))
    title = Column(String)
    description = Column(Text)
    price = Column(Float)
    city = Column(String)
    zone = Column(String)
    colony = Column(String, nullable=True)
    operation_type = Column(String) # sale, rent
    bedrooms = Column(Integer)
    bathrooms = Column(Integer)
    area = Column(Float)
    has_garage = Column(Boolean, default=False)
    has_garden = Column(Boolean, default=False)
    photos = Column(JSON) # JSON array
    status = Column(String, default="available")
    cluster = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    owner = relationship("User", back_populates="properties")

class Favorite(Base):
    __tablename__ = "favorites"
    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id"))
    property_id = Column(String, ForeignKey("properties.id"))
    saved_at = Column(DateTime, default=datetime.datetime.utcnow)

class SearchHistory(Base):
    __tablename__ = "search_history"
    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id"))
    query = Column(String)
    filters = Column(Text) # JSON
    searched_at = Column(DateTime, default=datetime.datetime.utcnow)

class Appointment(Base):
    __tablename__ = "appointments"
    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id"))
    seller_id = Column(String, ForeignKey("users.id"))
    property_id = Column(String, ForeignKey("properties.id"))
    scheduled_at = Column(DateTime)
    status = Column(String, default="pendiente")
    appointment_type = Column(String, default="presencial")
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class Notification(Base):
    __tablename__ = "notifications"
    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id"))
    title = Column(String)
    body = Column(String)
    type = Column(String)
    data = Column(Text, nullable=True)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class SellerSchedule(Base):
    __tablename__ = "seller_schedules"
    id = Column(String, primary_key=True, index=True)
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
    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id"))
    seller_id = Column(String, ForeignKey("users.id"))
    property_id = Column(String, ForeignKey("properties.id"))
    last_message_at = Column(DateTime, default=datetime.datetime.utcnow)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class Message(Base):
    __tablename__ = "messages"
    id = Column(String, primary_key=True, index=True)
    conversation_id = Column(String, ForeignKey("conversations.id"))
    sender_id = Column(String, ForeignKey("users.id"))
    content = Column(Text)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class FCMToken(Base):
    __tablename__ = "fcm_tokens"
    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    token = Column(String, nullable=False, unique=True)
    device = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)
