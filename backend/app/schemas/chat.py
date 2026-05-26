from pydantic import BaseModel
from datetime import datetime


class ConversationMessageOut(BaseModel):
    id: str
    role: str
    content: str
    document_id: str | None = None
    created_at: datetime
    model_config = {"from_attributes": True}


class ChatDocumentOut(BaseModel):
    id: str
    filename: str
    original_filename: str
    file_type: str
    file_size: int
    page_count: int | None = None
    is_processed: bool
    extracted_text: str | None = None
    created_at: datetime
    model_config = {"from_attributes": True}


class ConversationThreadOut(BaseModel):
    id: str
    title: str
    description: str | None = None
    is_active: bool
    created_at: datetime
    updated_at: datetime
    last_message_at: datetime | None = None
    model_config = {"from_attributes": True}


class ConversationDetailOut(ConversationThreadOut):
    messages: list[ConversationMessageOut]
    documents: list[ChatDocumentOut]


class CreateConversationRequest(BaseModel):
    title: str = "Nouvelle conversation"
    description: str | None = None


class SendMessageRequest(BaseModel):
    content: str
    document_id: str | None = None


class ChatMessageResponse(BaseModel):
    message_id: str
    reply: str
    created_at: datetime
