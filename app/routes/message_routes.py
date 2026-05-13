from fastapi import APIRouter

from app.schemas.request_schema import IncomingMessage
from app.schemas.response_schema import MessageResponse

from app.services.normalizer import normalize_message

router = APIRouter()


@router.post(
    "/webhook/message",
    response_model=MessageResponse
)
def receive_message(payload: IncomingMessage):

    normalized_message = normalize_message(payload)

    return {
        "message_id": normalized_message["message_id"],
        "query_type": "general_enquiry",
        "drafted_reply": f"Hello {payload.guest_name}, thank you for your message.",
        "confidence_score": 0.90,
        "action": "auto_send"
    }