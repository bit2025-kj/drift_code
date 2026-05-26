from datetime import datetime
from sqlalchemy import String, Integer, Float, Text, Boolean, DateTime, ForeignKey, JSON, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
import uuid


class Quiz(Base):
    __tablename__ = "quizzes"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    title: Mapped[str] = mapped_column(String(300))
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    matiere_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("matieres.id"), nullable=True)
    classe_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("classes.id"), nullable=True)
    level_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("education_levels.id"), nullable=True)

    difficulty: Mapped[str] = mapped_column(String(20), default="moyen")  # facile, moyen, difficile
    question_count: Mapped[int] = mapped_column(Integer, default=10)
    duration_minutes: Mapped[int] = mapped_column(Integer, default=30)

    is_ai_generated: Mapped[bool] = mapped_column(Boolean, default=False)
    is_public: Mapped[bool] = mapped_column(Boolean, default=True)
    created_by: Mapped[str | None] = mapped_column(String(36), ForeignKey("users.id"), nullable=True)

    plays_count: Mapped[int] = mapped_column(Integer, default=0)
    avg_score: Mapped[float] = mapped_column(Float, default=0.0)

    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    matiere = relationship("Matiere")
    classe = relationship("Classe")
    level = relationship("EducationLevel")
    creator = relationship("User", foreign_keys=[created_by])
    questions = relationship("Question", back_populates="quiz", cascade="all, delete-orphan")
    sessions = relationship("QuizSession", back_populates="quiz")


class Question(Base):
    __tablename__ = "questions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    quiz_id: Mapped[str] = mapped_column(String(36), ForeignKey("quizzes.id"))
    content: Mapped[str] = mapped_column(Text)
    options: Mapped[dict] = mapped_column(JSON)  # {"A": "...", "B": "...", "C": "...", "D": "..."}
    correct_answer: Mapped[str] = mapped_column(String(5))  # "A", "B", "C" ou "D"
    explanation: Mapped[str | None] = mapped_column(Text, nullable=True)
    order: Mapped[int] = mapped_column(Integer, default=0)
    points: Mapped[int] = mapped_column(Integer, default=1)

    quiz = relationship("Quiz", back_populates="questions")


class QuizSession(Base):
    __tablename__ = "quiz_sessions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"))
    quiz_id: Mapped[str] = mapped_column(String(36), ForeignKey("quizzes.id"))

    score: Mapped[float] = mapped_column(Float, default=0.0)  # pourcentage
    correct_answers: Mapped[int] = mapped_column(Integer, default=0)
    total_questions: Mapped[int] = mapped_column(Integer, default=0)
    answers: Mapped[dict | None] = mapped_column(JSON, nullable=True)  # {question_id: answer_chosen}

    is_completed: Mapped[bool] = mapped_column(Boolean, default=False)
    started_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    completed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    duration_seconds: Mapped[int] = mapped_column(Integer, default=0)

    user = relationship("User", back_populates="quiz_sessions")
    quiz = relationship("Quiz", back_populates="sessions")
