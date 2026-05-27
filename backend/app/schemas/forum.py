from pydantic import BaseModel
from datetime import datetime


class DiscussionCreate(BaseModel):
    title: str
    content: str
    category_id: int | None = None
    matiere_id: int | None = None
    classe_id: int | None = None
    media_urls: list[str] = []


class CommentCreate(BaseModel):
    content: str
    parent_id: str | None = None
    media_urls: list[str] = []


class AuthorOut(BaseModel):
    id: str
    full_name: str
    avatar_url: str | None
    points: int
    model_config = {"from_attributes": True}


class CommentOut(BaseModel):
    id: str
    content: str
    likes_count: int
    is_solution: bool
    created_at: datetime
    author: AuthorOut
    media_urls: list[str] = []
    parent_id: str | None = None
    replies: list["CommentOut"] = []
    liked_by_me: bool = False
    model_config = {"from_attributes": True}


class DiscussionOut(BaseModel):
    id: str
    title: str
    content: str
    views_count: int
    likes_count: int
    comments_count: int
    is_pinned: bool
    is_resolved: bool
    created_at: datetime
    author: AuthorOut
    category_name: str | None = None
    matiere_name: str | None = None
    media_urls: list[str] = []
    liked_by_me: bool = False
    model_config = {"from_attributes": True}


class DiscussionDetail(DiscussionOut):
    comments: list[CommentOut] = []


class ForumStats(BaseModel):
    total_members: int
    total_discussions: int
    online_count: int
