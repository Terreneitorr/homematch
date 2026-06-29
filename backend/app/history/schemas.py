from pydantic import BaseModel
from datetime import datetime

class HistoryResponse(BaseModel):
    id: str
    user_id: str
    query: str
    searched_at: datetime

    class Config:
        from_attributes = True