from pydantic import BaseModel
from datetime import datetime

class FavoriteResponse(BaseModel):
    id: str
    user_id: str
    property_id: str
    saved_at: datetime

    class Config:
        from_attributes = True