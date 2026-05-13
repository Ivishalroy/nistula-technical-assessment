from pydantic import BaseModel


class MessageResponse(BaseModel):
    message_id: str
    query_type: str
    drafted_reply: str
    confidence_score: float
    action: str