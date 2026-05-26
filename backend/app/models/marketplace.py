from datetime import datetime
from sqlalchemy import String, Integer, Float, Text, Boolean, DateTime, ForeignKey, func, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
import uuid


class Product(Base):
    __tablename__ = "products"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    title: Mapped[str] = mapped_column(String(300))
    description: Mapped[str] = mapped_column(Text)
    price: Mapped[int] = mapped_column(Integer)  # en FCFA

    product_type: Mapped[str] = mapped_column(String(50))  # cours, pack, resume, video, sujet_corrige
    teacher_id: Mapped[str] = mapped_column(String(36), ForeignKey("teacher_profiles.id"))

    matiere_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("matieres.id"), nullable=True)
    classe_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("classes.id"), nullable=True)
    level_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("education_levels.id"), nullable=True)

    thumbnail_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # Multi-media support: list of {"url": "...", "type": "pdf|image|video", "name": "..."}
    media_urls: Mapped[list] = mapped_column(JSON, default=list)

    # Pack: list of {"title": "...", "description": "...", "url": "...", "type": "pdf|video|image", "order": 0}
    pack_items: Mapped[list] = mapped_column(JSON, default=list)

    rating: Mapped[float] = mapped_column(Float, default=0.0)
    ratings_count: Mapped[int] = mapped_column(Integer, default=0)
    purchases_count: Mapped[int] = mapped_column(Integer, default=0)
    views_count: Mapped[int] = mapped_column(Integer, default=0)

    is_featured: Mapped[bool] = mapped_column(Boolean, default=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    discount_percent: Mapped[int] = mapped_column(Integer, default=0)

    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    teacher = relationship("TeacherProfile", back_populates="products")
    matiere = relationship("Matiere")
    classe = relationship("Classe")
    level = relationship("EducationLevel")
    purchases = relationship("Purchase", back_populates="product")


class Purchase(Base):
    __tablename__ = "purchases"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"))
    product_id: Mapped[str] = mapped_column(String(36), ForeignKey("products.id"))
    amount: Mapped[int] = mapped_column(Integer)  # FCFA payé
    payment_method: Mapped[str | None] = mapped_column(String(50), nullable=True)
    transaction_id: Mapped[str | None] = mapped_column(String(100), nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="completed")
    purchased_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    user = relationship("User", back_populates="purchases")
    product = relationship("Product", back_populates="purchases")


class TeacherRequest(Base):
    """Demande pour devenir enseignant sur la plateforme."""
    __tablename__ = "teacher_requests"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), unique=True)

    bio: Mapped[str] = mapped_column(Text)
    specialites: Mapped[str] = mapped_column(String(500))
    etablissement: Mapped[str | None] = mapped_column(String(200), nullable=True)
    annees_experience: Mapped[int] = mapped_column(Integer, default=0)
    justification: Mapped[str] = mapped_column(Text)  # Pourquoi devenir prof
    document_url: Mapped[str | None] = mapped_column(String(500), nullable=True)  # Pièce justificative

    # pending | approved | rejected
    status: Mapped[str] = mapped_column(String(20), default="pending")
    admin_note: Mapped[str | None] = mapped_column(Text, nullable=True)
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    user = relationship("User", foreign_keys=[user_id])
