from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.models import SearchHistory, User
from app.auth.dependencies import get_current_user
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