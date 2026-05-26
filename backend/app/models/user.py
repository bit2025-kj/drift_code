from datetime import datetime
from sqlalchemy import String, Boolean, Integer, Float, Text, DateTime, func, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
import uuid


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    phone: Mapped[str | None] = mapped_column(String(20), unique=True, nullable=True)
    full_name: Mapped[str] = mapped_column(String(150))
    password_hash: Mapped[str] = mapped_column(String(255))
    avatar_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # Profil scolaire
    level_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("education_levels.id"), nullable=True)
    classe_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("classes.id"), nullable=True)
    ville: Mapped[str | None] = mapped_column(String(100), nullable=True)

    # Statuts
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_teacher: Mapped[bool] = mapped_column(Boolean, default=False)
    is_admin: Mapped[bool] = mapped_column(Boolean, default=False)
    email_verified: Mapped[bool] = mapped_column(Boolean, default=False)

    # Gamification
    points: Mapped[int] = mapped_column(Integer, default=0)
    active_days: Mapped[int] = mapped_column(Integer, default=0)
    current_streak: Mapped[int] = mapped_column(Integer, default=0)
    rank: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # Portefeuille (FCFA)
    wallet_balance: Mapped[int] = mapped_column(Integer, default=0)

    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    # Relations
    level = relationship("EducationLevel", foreign_keys=[level_id])
    classe = relationship("Classe", foreign_keys=[classe_id])
    teacher_profile = relationship("TeacherProfile", back_populates="user", uselist=False)
    badges = relationship("UserBadge", back_populates="user")
    downloads = relationship("Download", back_populates="user")
    favorites = relationship("Favorite", back_populates="user")
    quiz_sessions = relationship("QuizSession", back_populates="user")
    purchases = relationship("Purchase", back_populates="user")


class TeacherProfile(Base):
    __tablename__ = "teacher_profiles"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), unique=True)
    bio: Mapped[str | None] = mapped_column(Text, nullable=True)
    specialites: Mapped[str | None] = mapped_column(String(500), nullable=True)
    etablissement: Mapped[str | None] = mapped_column(String(200), nullable=True)
    annees_experience: Mapped[int] = mapped_column(Integer, default=0)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    verified_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    rating: Mapped[float] = mapped_column(Float, default=0.0)
    total_sales: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    user = relationship("User", back_populates="teacher_profile")
    products = relationship("Product", back_populates="teacher")
