from pydantic import BaseModel
from datetime import datetime


class NotificationOut(BaseModel):
    id: int
    type: str
    title: str
    body: str
    data: dict | None = None
    is_read: bool
    created_at: datetime

    model_config = {"from_attributes": True}
