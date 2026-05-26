from datetime import datetime
from sqlalchemy import String, Integer, Text, DateTime, ForeignKey, Boolean, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
import uuid


class ConversationThread(Base):
    __tablename__ = "conversation_threads"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), index=True)
    title: Mapped[str] = mapped_column(String(255), default="Nouvelle conversation")
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), index=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())
    last_message_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    messages = relationship("ConversationMessage", back_populates="thread", cascade="all, delete-orphan")
    documents = relationship("ChatDocument", back_populates="thread", cascade="all, delete-orphan")


class ConversationMessage(Base):
    __tablename__ = "conversation_messages"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    thread_id: Mapped[str] = mapped_column(String(36), ForeignKey("conversation_threads.id"), index=True)
    role: Mapped[str] = mapped_column(String(20))  # "user" or "assistant"
    content: Mapped[str] = mapped_column(Text)
    
    # Si le message est lié à un document
    document_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("chat_documents.id"), nullable=True)
    
    # Pour l'offline sync
    is_synced: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), index=True)

    thread = relationship("ConversationThread", back_populates="messages")
    document = relationship("ChatDocument", back_populates="messages")


class ChatDocument(Base):
    __tablename__ = "chat_documents"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    thread_id: Mapped[str] = mapped_column(String(36), ForeignKey("conversation_threads.id"), index=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), index=True)
    
    filename: Mapped[str] = mapped_column(String(500))
    original_filename: Mapped[str] = mapped_column(String(500))
    file_type: Mapped[str] = mapped_column(String(50))  # "pdf", "image", "text", etc.
    file_size: Mapped[int] = mapped_column(Integer)  # bytes
    file_path: Mapped[str] = mapped_column(String(500))  # relative path in uploads/
    
    # Métadonnées extraites
    extracted_text: Mapped[str | None] = mapped_column(Text, nullable=True)
    page_count: Mapped[int | None] = mapped_column(Integer, nullable=True)  # pour PDFs
    is_processed: Mapped[bool] = mapped_column(Boolean, default=False)
    
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    thread = relationship("ConversationThread", back_populates="documents")
    messages = relationship("ConversationMessage", back_populates="document")
