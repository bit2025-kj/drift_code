from sqlalchemy.ext.asyncio import AsyncSession
from app.models.notification import Notification


async def push_notif(
    db: AsyncSession,
    user_id: str,
    type: str,
    title: str,
    body: str,
    data: dict | None = None,
    exclude_user_id: str | None = None,
) -> None:
    """Create a notification for user_id. Pass exclude_user_id to skip self-notifications."""
    if not user_id or user_id == exclude_user_id:
        return
    db.add(Notification(user_id=user_id, type=type, title=title, body=body, data=data))
