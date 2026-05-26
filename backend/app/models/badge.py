from datetime import datetime
from sqlalchemy import String, Integer, Text, Boolean, DateTime, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base


class Badge(Base):
    __tablename__ = "badges"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(100), unique=True)
    description: Mapped[str] = mapped_column(Text)
    icon: Mapped[str] = mapped_column(String(50))
    color: Mapped[str] = mapped_column(String(20))

    # Condition d'obtention
    condition_type: Mapped[str] = mapped_column(String(50))
    # "downloads", "quiz_streak", "quiz_score", "forum_posts",
    # "active_days", "purchases", "points"
    condition_value: Mapped[int] = mapped_column(Integer, default=1)

    points_reward: Mapped[int] = mapped_column(Integer, default=50)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    user_badges = relationship("UserBadge", back_populates="badge")


class UserBadge(Base):
    __tablename__ = "user_badges"

    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), primary_key=True)
    badge_id: Mapped[int] = mapped_column(Integer, ForeignKey("badges.id"), primary_key=True)
    earned_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    user = relationship("User", back_populates="badges")
    badge = relationship("Badge", back_populates="user_badges")
