from pydantic import BaseModel, field_validator
from datetime import datetime


class ProductMediaItem(BaseModel):
    url: str
    type: str  # "pdf" | "image" | "video"
    name: str = ""


class PackItemSchema(BaseModel):
    title: str
    description: str = ""
    url: str
    type: str  # "pdf" | "video" | "image"
    order: int = 0


class ProductOut(BaseModel):
    id: str
    title: str
    description: str
    price: int
    product_type: str
    thumbnail_url: str | None
    media_urls: list[dict] = []
    pack_items: list[dict] = []
    rating: float
    ratings_count: int
    purchases_count: int
    is_featured: bool
    discount_percent: int
    matiere_name: str | None = None
    classe_name: str | None = None
    level_name: str | None = None
    teacher_name: str | None = None
    teacher_id: str | None = None
    teacher_user_id: str | None = None
    teacher_verified: bool = False
    effective_price: int = 0
    created_at: datetime
    model_config = {"from_attributes": True}


class ProductCreate(BaseModel):
    title: str
    description: str
    price: int
    product_type: str
    matiere_id: int | None = None
    classe_id: int | None = None
    level_id: int | None = None
    discount_percent: int = 0
    media_urls: list[dict] = []
    pack_items: list[dict] = []

    @field_validator("product_type")
    @classmethod
    def validate_type(cls, v: str) -> str:
        allowed = {"cours", "pack", "resume", "video", "sujet_corrige"}
        if v not in allowed:
            raise ValueError(f"Type doit être l'un de: {', '.join(allowed)}")
        return v

    @field_validator("price")
    @classmethod
    def validate_price(cls, v: int) -> int:
        if v < 0:
            raise ValueError("Le prix ne peut pas être négatif")
        return v


class ProductUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    price: int | None = None
    discount_percent: int | None = None
    media_urls: list[dict] | None = None
    pack_items: list[dict] | None = None
    thumbnail_url: str | None = None
    is_featured: bool | None = None


class ProductListResponse(BaseModel):
    total: int
    page: int
    per_page: int
    items: list[ProductOut]


class PurchaseResponse(BaseModel):
    purchase_id: str
    product_title: str
    amount_paid: int
    media_urls: list[dict] = []
    message: str


class MarketplaceFilter(BaseModel):
    product_type: str | None = None
    matiere_id: int | None = None
    classe_id: int | None = None
    level_id: int | None = None
    max_price: int | None = None
    min_price: int | None = None
    q: str | None = None
    sort_by: str = "popular"
    page: int = 1
    per_page: int = 20


class TeacherRequestCreate(BaseModel):
    bio: str
    specialites: str
    etablissement: str | None = None
    annees_experience: int = 0
    justification: str


class TeacherRequestOut(BaseModel):
    id: str
    status: str  # pending | approved | rejected
    bio: str
    specialites: str
    etablissement: str | None
    annees_experience: int
    justification: str
    document_url: str | None
    admin_note: str | None
    created_at: datetime
    reviewed_at: datetime | None
    model_config = {"from_attributes": True}


class AdminReviewRequest(BaseModel):
    status: str  # approved | rejected
    admin_note: str | None = None
