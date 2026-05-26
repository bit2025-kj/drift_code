from datetime import datetime
from sqlalchemy import String, Integer, Float, Text, Boolean, DateTime, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
import uuid


class Document(Base):
    __tablename__ = "documents"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    title: Mapped[str] = mapped_column(String(300))
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Classification
    level_id: Mapped[int] = mapped_column(Integer, ForeignKey("education_levels.id"))
    classe_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("classes.id"), nullable=True)
    matiere_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("matieres.id"), nullable=True)
    type_examen_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("types_examens.id"), nullable=True)
    annee: Mapped[int | None] = mapped_column(Integer, nullable=True)
    session: Mapped[str | None] = mapped_column(String(50), nullable=True)  # "Juin", "Septembre"

    # Fichiers
    file_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    corrige_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    file_size_kb: Mapped[int] = mapped_column(Integer, default=0)

    # Métadonnées
    is_official: Mapped[bool] = mapped_column(Boolean, default=False)
    has_corrige: Mapped[bool] = mapped_column(Boolean, default=False)
    downloads_count: Mapped[int] = mapped_column(Integer, default=0)
    views_count: Mapped[int] = mapped_column(Integer, default=0)
    rating: Mapped[float] = mapped_column(Float, default=0.0)
    ratings_count: Mapped[int] = mapped_column(Integer, default=0)

    # Source
    uploaded_by: Mapped[str | None] = mapped_column(String(36), ForeignKey("users.id"), nullable=True)
    is_approved: Mapped[bool] = mapped_column(Boolean, default=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    # Relations
    level = relationship("EducationLevel")
    classe = relationship("Classe")
    matiere = relationship("Matiere")
    type_examen = relationship("TypeExamen")
    uploader = relationship("User", foreign_keys=[uploaded_by])
    favorites = relationship("Favorite", back_populates="document")
    downloads = relationship("Download", back_populates="document")


class Favorite(Base):
    __tablename__ = "favorites"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), primary_key=True)
    document_id: Mapped[str] = mapped_column(String(36), ForeignKey("documents.id"), primary_key=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    user = relationship("User", back_populates="favorites")
    document = relationship("Document", back_populates="favorites")


class Download(Base):
    __tablename__ = "downloads"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"))
    document_id: Mapped[str] = mapped_column(String(36), ForeignKey("documents.id"))
    downloaded_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    is_corrige: Mapped[bool] = mapped_column(Boolean, default=False)

    user = relationship("User", back_populates="downloads")
    document = relationship("Document", back_populates="downloads")
