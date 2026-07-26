from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.infrastructure.database.database import get_db
from app.infrastructure.database.models import User, Conversation, Message, Property
from app.infrastructure.security.dependencies import get_current_user
from app.fcm.router import notify_message
from app.moderation import get_first_bad_word
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import uuid

class MessageCreate(BaseModel):
    content: str
    reply_to_id: Optional[str] = None

class MessageResponse(BaseModel):
    id: str
    conversation_id: str
    sender_id: str
    content: str
    is_read: bool
    created_at: datetime
    deleted: bool = False
    reply_to_id: Optional[str] = None
    reply_to_content: Optional[str] = None
    reply_to_sender_id: Optional[str] = None

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


def _to_message_response(db: Session, msg: Message) -> MessageResponse:
    """Arma la respuesta de un mensaje, incluyendo la vista previa del
    mensaje al que responde (si aplica)."""
    reply_content = None
    reply_sender_id = None
    if msg.reply_to_id:
        original = db.query(Message).filter(Message.id == msg.reply_to_id).first()
        if original:
            reply_content = "Mensaje eliminado" if original.deleted else original.content
            reply_sender_id = original.sender_id

    return MessageResponse(
        id=msg.id,
        conversation_id=msg.conversation_id,
        sender_id=msg.sender_id,
        content="Mensaje eliminado" if msg.deleted else msg.content,
        is_read=msg.is_read,
        created_at=msg.created_at,
        deleted=msg.deleted or False,
        reply_to_id=msg.reply_to_id,
        reply_to_content=reply_content,
        reply_to_sender_id=reply_sender_id,
    )


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

        last_msg_preview = None
        if last_msg:
            last_msg_preview = "Mensaje eliminado" if last_msg.deleted else last_msg.content

        result.append(ConversationResponse(
            id=conv.id,
            user_id=conv.user_id,
            seller_id=conv.seller_id,
            property_id=conv.property_id,
            property_title=prop_title,
            property_photo=prop_photo,
            created_at=conv.created_at,
            last_message_at=conv.last_message_at,
            last_message=last_msg_preview,
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
    db.query(Message).filter(
        Message.conversation_id == conversation_id,
        Message.sender_id != current_user.id,
        Message.is_read == False
    ).update({"is_read": True})
    db.commit()

    messages = db.query(Message).filter(
        Message.conversation_id == conversation_id
    ).order_by(Message.created_at.asc()).all()

    return [_to_message_response(db, m) for m in messages]

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

    bad_word = get_first_bad_word(data.content)
    if bad_word:
        raise HTTPException(
            status_code=400,
            detail=f"Tu mensaje contiene lenguaje inapropiado ('{bad_word}')",
        )

    if data.reply_to_id:
        original = db.query(Message).filter(
            Message.id == data.reply_to_id,
            Message.conversation_id == conversation_id,
            ).first()
        if not original:
            raise HTTPException(status_code=404, detail="Mensaje original no encontrado")

    msg = Message(
        id=str(uuid.uuid4()),
        conversation_id=conversation_id,
        sender_id=current_user.id,
        content=data.content,
        reply_to_id=data.reply_to_id,
    )
    db.add(msg)
    conv.last_message_at = datetime.utcnow()
    db.commit()
    db.refresh(msg)

    receiver_id = (
        conv.seller_id
        if current_user.id == conv.user_id
        else conv.user_id
    )
    notify_message(
        db=db,
        receiver_id=receiver_id,
        sender_name=current_user.name,
        message_content=data.content,
        conversation_id=conversation_id,
    )

    return _to_message_response(db, msg)


@router.delete("/conversations/{conversation_id}/messages/{message_id}")
def delete_message(
        conversation_id: str,
        message_id: str,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user),
):
    msg = db.query(Message).filter(
        Message.id == message_id,
        Message.conversation_id == conversation_id,
        ).first()
    if not msg:
        raise HTTPException(status_code=404, detail="Mensaje no encontrado")
    if msg.sender_id != current_user.id:
        raise HTTPException(status_code=403, detail="Solo puedes borrar tus propios mensajes")

    msg.deleted = True
    db.commit()
    return {"message": "Mensaje eliminado para todos"}


@router.delete("/conversations/{conversation_id}")
def delete_conversation(
        conversation_id: str,
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user),
):
    conv = db.query(Conversation).filter(Conversation.id == conversation_id).first()
    if not conv:
        raise HTTPException(status_code=404, detail="Conversación no encontrada")
    if current_user.id not in (conv.user_id, conv.seller_id):
        raise HTTPException(status_code=403, detail="Sin permiso")

    db.query(Message).filter(Message.conversation_id == conversation_id).delete()
    db.delete(conv)
    db.commit()
    return {"message": "Conversación eliminada"}