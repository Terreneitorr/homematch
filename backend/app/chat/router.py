from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User, Conversation, Message, Property
from app.auth.dependencies import get_current_user
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import uuid

class MessageCreate(BaseModel):
    content: str

class MessageResponse(BaseModel):
    id: str
    conversation_id: str
    sender_id: str
    content: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True

class ConversationResponse(BaseModel):
    id: str
    user_id: str
    seller_id: str
    property_id: Optional[str]
    property_title: Optional[str] = None
    property_photo: Optional[str] = None
    created_at: datetime
    last_message_at: datetime
    last_message: Optional[str] = None
    unread_count: int = 0

    class Config:
        from_attributes = True

router = APIRouter()

@router.get("/conversations", response_model=List[ConversationResponse])
def get_conversations(
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    convs = db.query(Conversation).filter(
        (Conversation.user_id == current_user.id) |
        (Conversation.seller_id == current_user.id)
    ).order_by(Conversation.last_message_at.desc()).all()

    result = []
    for conv in convs:
        last_msg = db.query(Message).filter(
            Message.conversation_id == conv.id
        ).order_by(Message.created_at.desc()).first()

        unread = db.query(Message).filter(
            Message.conversation_id == conv.id,
            Message.sender_id != current_user.id,
            Message.is_read == False
        ).count()
        
        prop_title = None
        prop_photo = None
        if conv.property_id:
            prop = db.query(Property).filter(Property.id == conv.property_id).first()
            if prop:
                prop_title = prop.title
                if prop.photos:
                    prop_photo = prop.photos[0]

        result.append(ConversationResponse(
            id=conv.id,
            user_id=conv.user_id,
            seller_id=conv.seller_id,
            property_id=conv.property_id,
            property_title=prop_title,
            property_photo=prop_photo,
            created_at=conv.created_at,
            last_message_at=conv.last_message_at,
            last_message=last_msg.content if last_msg else None,
            unread_count=unread,
        ))
    return result

@router.post("/conversations/{seller_id}", response_model=ConversationResponse)
def start_conversation(
        seller_id: str,
        property_id: Optional[str] = None,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    # Verificar si ya existe
    existing = db.query(Conversation).filter(
        Conversation.user_id == current_user.id,
        Conversation.seller_id == seller_id,
        Conversation.property_id == property_id,
        ).first()

    if existing:
        prop_title = None
        prop_photo = None
        if existing.property_id:
            prop = db.query(Property).filter(Property.id == existing.property_id).first()
            if prop:
                prop_title = prop.title
                if prop.photos:
                    prop_photo = prop.photos[0]

        return ConversationResponse(
            id=existing.id,
            user_id=existing.user_id,
            seller_id=existing.seller_id,
            property_id=existing.property_id,
            property_title=prop_title,
            property_photo=prop_photo,
            created_at=existing.created_at,
            last_message_at=existing.last_message_at,
        )

    conv = Conversation(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        seller_id=seller_id,
        property_id=property_id,
    )
    db.add(conv)
    db.commit()
    db.refresh(conv)
    
    prop_title = None
    prop_photo = None
    if conv.property_id:
        prop = db.query(Property).filter(Property.id == conv.property_id).first()
        if prop:
            prop_title = prop.title
            if prop.photos:
                prop_photo = prop.photos[0]

    return ConversationResponse(
        id=conv.id,
        user_id=conv.user_id,
        seller_id=conv.seller_id,
        property_id=conv.property_id,
        property_title=prop_title,
        property_photo=prop_photo,
        created_at=conv.created_at,
        last_message_at=conv.last_message_at,
    )

@router.get("/conversations/{conversation_id}/messages",
            response_model=List[MessageResponse])
def get_messages(
        conversation_id: str,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    # Marcar como leídos
    db.query(Message).filter(
        Message.conversation_id == conversation_id,
        Message.sender_id != current_user.id,
        Message.is_read == False
    ).update({"is_read": True})
    db.commit()

    return db.query(Message).filter(
        Message.conversation_id == conversation_id
    ).order_by(Message.created_at.asc()).all()

@router.post("/conversations/{conversation_id}/messages",
             response_model=MessageResponse)
def send_message(
        conversation_id: str,
        data: MessageCreate,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    conv = db.query(Conversation).filter(
        Conversation.id == conversation_id
    ).first()
    if not conv:
        raise HTTPException(status_code=404, detail="Conversación no encontrada")

    msg = Message(
        id=str(uuid.uuid4()),
        conversation_id=conversation_id,
        sender_id=current_user.id,
        content=data.content,
    )
    db.add(msg)
    conv.last_message_at = datetime.utcnow()
    db.commit()
    db.refresh(msg)
    return msg