from fastapi import APIRouter

from app.schemas.request_schema import IncomingMessage
from app.schemas.response_schema import MessageResponse

from app.services.normalizer import normalize_message
from app.services.classifier import classify_query

router = APIRouter()


@router.post(
    "/webhook/message",
    response_model=MessageResponse
)
def receive_message(payload: IncomingMessage):

    normalized_message = normalize_message(payload)

    query_type = classify_query(
        normalized_message["message_text"]
    )

    return {
        "message_id": normalized_message["message_id"],
        "query_type": query_type,
        "drafted_reply": f"Hello {payload.guest_name}, thank you for your message.",
        "confidence_score": 0.90,
        "action": "auto_send"
    }