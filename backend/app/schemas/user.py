from pydantic import BaseModel, EmailStr
from datetime import datetime


class UserProfile(BaseModel):
    id: str
    full_name: str
    email: EmailStr
    phone: str | None
    avatar_url: str | None
    level_id: int | None
    classe_id: int | None
    ville: str | None
    is_teacher: bool
    points: int
    active_days: int
    current_streak: int
    rank: int | None
    wallet_balance: int
    level_name: str | None = None
    classe_name: str | None = None
    created_at: datetime
    model_config = {"from_attributes": True}


class UserStats(BaseModel):
    total_downloads: int
    total_favorites: int
    total_quiz_sessions: int
    avg_quiz_score: float
    total_forum_posts: int
    total_purchases: int
    badges_count: int
    revision_hours: float
    subject_progress: list[dict]


class UpdateProfileRequest(BaseModel):
    full_name: str | None = None
    phone: str | None = None
    level_id: int | None = None
    classe_id: int | None = None
    ville: str | None = None


class BadgeOut(BaseModel):
    id: int
    name: str
    description: str
    icon: str
    color: str
    earned_at: datetime
    model_config = {"from_attributes": True}
