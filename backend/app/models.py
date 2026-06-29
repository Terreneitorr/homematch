from sqlalchemy import Column, String, Float, Integer, Boolean, DateTime, Enum, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import enum

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
    photos = Column(String, default="[]")
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