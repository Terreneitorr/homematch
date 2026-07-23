from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from app.infrastructure.database.database import get_db
from app.infrastructure.database.models import SearchHistory, User
from app.infrastructure.security.dependencies import get_current_user
from app.history.schemas import HistoryResponse
import uuid

router = APIRouter()

@router.get("/", response_model=List[HistoryResponse])
def get_history(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(SearchHistory).filter(
        SearchHistory.user_id == current_user.id
    ).order_by(SearchHistory.searched_at.desc()).limit(50).all()

@router.post("/")
def add_history(query: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    entry = SearchHistory(id=str(uuid.uuid4()), user_id=current_user.id, query=query)
    db.add(entry)
    db.commit()
    return {"message": "Guardado"}

@router.delete("/")
def clear_history(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Borra TODO el historial de búsquedas del usuario actual."""
    db.query(SearchHistory).filter(
        SearchHistory.user_id == current_user.id
    ).delete()
    db.commit()
    return {"message": "Historial eliminado"}