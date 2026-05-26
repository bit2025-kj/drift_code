from datetime import datetime
from sqlalchemy import String, Integer, Text, Boolean, DateTime, ForeignKey, func, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
import uuid


class ForumCategory(Base):
    __tablename__ = "forum_categories"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(100), unique=True)
    slug: Mapped[str] = mapped_column(String(80), unique=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    icon: Mapped[str | None] = mapped_column(String(50), nullable=True)
    color: Mapped[str | None] = mapped_column(String(20), nullable=True)
    order: Mapped[int] = mapped_column(Integer, default=0)

    discussions = relationship("Discussion", back_populates="category")


class Discussion(Base):
    __tablename__ = "discussions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    title: Mapped[str] = mapped_column(String(400))
    content: Mapped[str] = mapped_column(Text)

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"))
    category_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("forum_categories.id"), nullable=True)
    matiere_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("matieres.id"), nullable=True)
    classe_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("classes.id"), nullable=True)

    media_urls: Mapped[list] = mapped_column(JSON, default=list)

    views_count: Mapped[int] = mapped_column(Integer, default=0)
    likes_count: Mapped[int] = mapped_column(Integer, default=0)
    comments_count: Mapped[int] = mapped_column(Integer, default=0)

    is_pinned: Mapped[bool] = mapped_column(Boolean, default=False)
    is_resolved: Mapped[bool] = mapped_column(Boolean, default=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    author = relationship("User", foreign_keys=[user_id])
    category = relationship("ForumCategory", back_populates="discussions")
    matiere = relationship("Matiere")
    classe = relationship("Classe")
    comments = relationship("DiscussionComment", back_populates="discussion", cascade="all, delete-orphan")


class DiscussionComment(Base):
    __tablename__ = "discussion_comments"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    discussion_id: Mapped[str] = mapped_column(String(36), ForeignKey("discussions.id"))
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"))
    parent_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("discussion_comments.id"), nullable=True)

    content: Mapped[str] = mapped_column(Text)
    media_urls: Mapped[list] = mapped_column(JSON, default=list)
    likes_count: Mapped[int] = mapped_column(Integer, default=0)
    is_solution: Mapped[bool] = mapped_column(Boolean, default=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    author = relationship("User", foreign_keys=[user_id])
    discussion = relationship("Discussion", back_populates="comments")
    replies = relationship("DiscussionComment", foreign_keys=[parent_id])
