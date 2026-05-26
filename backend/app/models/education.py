from sqlalchemy import String, Integer, ForeignKey, Table, Column
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base


# Table d'association matière <-> classe
matiere_classe = Table(
    "matiere_classe",
    Base.metadata,
    Column("matiere_id", Integer, ForeignKey("matieres.id"), primary_key=True),
    Column("classe_id", Integer, ForeignKey("classes.id"), primary_key=True),
)


class EducationLevel(Base):
    __tablename__ = "education_levels"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(100), unique=True)
    slug: Mapped[str] = mapped_column(String(50), unique=True)
    order: Mapped[int] = mapped_column(Integer, default=0)
    icon: Mapped[str | None] = mapped_column(String(50), nullable=True)
    color: Mapped[str | None] = mapped_column(String(20), nullable=True)

    classes = relationship("Classe", back_populates="level", order_by="Classe.order")


class Classe(Base):
    __tablename__ = "classes"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    level_id: Mapped[int] = mapped_column(Integer, ForeignKey("education_levels.id"))
    name: Mapped[str] = mapped_column(String(100))
    slug: Mapped[str] = mapped_column(String(50), unique=True)
    order: Mapped[int] = mapped_column(Integer, default=0)

    level = relationship("EducationLevel", back_populates="classes")
    matieres = relationship("Matiere", secondary=matiere_classe, back_populates="classes")


class Matiere(Base):
    __tablename__ = "matieres"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(150), unique=True)
    slug: Mapped[str] = mapped_column(String(100), unique=True)
    icon: Mapped[str | None] = mapped_column(String(50), nullable=True)
    color: Mapped[str | None] = mapped_column(String(20), nullable=True)

    classes = relationship("Classe", secondary=matiere_classe, back_populates="matieres")


class TypeExamen(Base):
    __tablename__ = "types_examens"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(150))
    slug: Mapped[str] = mapped_column(String(100), unique=True)
    level_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("education_levels.id"), nullable=True)
    is_national: Mapped[bool] = mapped_column(default=False)
    order: Mapped[int] = mapped_column(Integer, default=0)

    level = relationship("EducationLevel")
