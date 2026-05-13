from fastapi import APIRouter

router = APIRouter()

@router.post("/webhook/message")
def receive_message():
    return {
        "status": "success",
        "message": "Webhook endpoint working"
    }