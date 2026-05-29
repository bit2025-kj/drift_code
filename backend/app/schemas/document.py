from pydantic import BaseModel
from datetime import datetime


class DocumentOut(BaseModel):
    id: str
    title: str
    description: str | None
    level_id: int
    classe_id: int | None
    matiere_id: int | None
    type_examen_id: int | None
    annee: int | None
    session: str | None
    is_official: bool
    has_corrige: bool
    downloads_count: int
    views_count: int
    likes_count: int = 0
    file_size_kb: int
    created_at: datetime

    file_url: str | None = None
    file_type: str | None = None
    thumbnail_url: str | None = None

    corrige_url: str | None = None
    corrige_file_type: str | None = None

    uploaded_by: str | None = None
    uploader_name: str | None = None
    uploader_avatar: str | None = None

    level_name: str | None = None
    classe_name: str | None = None
    matiere_name: str | None = None
    type_examen_name: str | None = None

    model_config = {"from_attributes": True}


class DocumentFilter(BaseModel):
    level_id: int | None = None
    classe_id: int | None = None
    matiere_id: int | None = None
    type_examen_id: int | None = None
    annee: int | None = None
    has_corrige: bool | None = None
    is_official: bool | None = None
    q: str | None = None
    sort_by: str = "recent"  # "recent", "popular", "likes"
    page: int = 1
    per_page: int = 20


class DocumentListResponse(BaseModel):
    total: int
    page: int
    per_page: int
    items: list[DocumentOut]


class FavoriteToggleResponse(BaseModel):
    is_favorite: bool
    message: str
