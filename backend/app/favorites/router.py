from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.infrastructure.database.database import get_db
from app.infrastructure.database.models import Favorite, User
from app.infrastructure.security.dependencies import get_current_user
from app.favorites.schemas import FavoriteResponse
import uuid

router = APIRouter()

@router.get("/", response_model=List[FavoriteResponse])
def get_favorites(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(Favorite).filter(Favorite.user_id == current_user.id).all()

@router.post("/{property_id}", response_model=FavoriteResponse)
def add_favorite(property_id: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    existing = db.query(Favorite).filter(
        Favorite.user_id == current_user.id,
        Favorite.property_id == property_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Ya está en favoritos")
    fav = Favorite(id=str(uuid.uuid4()), user_id=current_user.id, property_id=property_id)
    db.add(fav)
    db.commit()
    db.refresh(fav)
    return fav

@router.delete("/{property_id}")
def remove_favorite(property_id: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    fav = db.query(Favorite).filter(
        Favorite.user_id == current_user.id,
        Favorite.property_id == property_id
    ).first()
    if not fav:
        raise HTTPException(status_code=404, detail="No encontrado")
    db.delete(fav)
    db.commit()
    return {"message": "Eliminado de favoritos"}