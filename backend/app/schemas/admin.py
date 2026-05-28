from pydantic import BaseModel
from datetime import datetime


class AdminStats(BaseModel):
    total_users: int
    active_users: int
    total_teachers: int
    total_documents: int
    total_products: int
    pending_teacher_requests: int
    pending_reports: int


class UserListItem(BaseModel):
    id: str
    full_name: str
    email: str
    phone: str | None
    ville: str | None
    is_active: bool
    is_teacher: bool
    is_admin: bool
    points: int
    created_at: datetime
    model_config = {"from_attributes": True}


class UserActivity(BaseModel):
    downloads_count: int
    favorites_count: int
    quiz_sessions_count: int
    forum_posts_count: int
    purchases_count: int


class UserDetailAdmin(BaseModel):
    id: str
    full_name: str
    email: str
    phone: str | None
    ville: str | None
    is_active: bool
    is_teacher: bool
    is_admin: bool
    points: int
    wallet_balance: int
    current_streak: int
    active_days: int
    created_at: datetime
    activity: UserActivity
    model_config = {"from_attributes": True}


class UserStatusUpdate(BaseModel):
    is_active: bool


class ReportCreate(BaseModel):
    reason: str   # contenu_inapproprie | triche | spam | droits_auteur | autre
    description: str | None = None


class ReportOut(BaseModel):
    id: str
    reporter_id: str
    reporter_name: str | None = None
    content_type: str
    content_id: str
    content_title: str | None = None
    reason: str
    description: str | None
    status: str
    admin_note: str | None
    resolved_by: str | None
    resolved_at: datetime | None
    created_at: datetime
    model_config = {"from_attributes": True}


class ReportResolveRequest(BaseModel):
    status: str          # resolved | dismissed
    admin_note: str | None = None
    delete_content: bool = False


class TeacherRequestAdminOut(BaseModel):
    id: str
    status: str
    bio: str
    specialites: str
    etablissement: str | None
    annees_experience: int
    justification: str
    document_url: str | None
    admin_note: str | None
    created_at: datetime
    reviewed_at: datetime | None
    user_id: str
    user_name: str | None = None
    user_email: str | None = None
    model_config = {"from_attributes": True}


class AdminReviewRequest(BaseModel):
    status: str          # approved | rejected
    admin_note: str | None = None
