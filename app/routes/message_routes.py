from fastapi import APIRouter

from app.schemas.request_schema import IncomingMessage
from app.schemas.response_schema import MessageResponse

from app.services.normalizer import normalize_message
from app.services.classifier import classify_query
from app.services.claude_service import generate_guest_reply

from app.services.confidence_service import calculate_confidence_score
from app.services.action_service import determine_action

from app.prompts.guest_reply_prompt import build_guest_prompt

router = APIRouter()


@router.post(
    "/webhook/message",
    response_model=MessageResponse
)
def receive_message(payload: IncomingMessage):

    try:

        normalized_message = normalize_message(payload)

        query_type = classify_query(
            normalized_message["message_text"]
        )

        prompt = build_guest_prompt(
            normalized_message,
            query_type
        )

        drafted_reply = generate_guest_reply(prompt)

        confidence_score = calculate_confidence_score(
            query_type,
            normalized_message["message_text"]
        )

        action = determine_action(
            confidence_score,
            query_type,
            normalized_message["message_text"]
        )

        return {
            "message_id": normalized_message["message_id"],
            "query_type": query_type,
            "drafted_reply": drafted_reply,
            "confidence_score": confidence_score,
            "action": action
        }

    except Exception as error:

        print("APPLICATION ERROR:")
        print(error)

        raise HTTPException(
            status_code=500,
            detail="Internal server error"
        )