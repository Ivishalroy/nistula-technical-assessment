from fastapi import FastAPI
from app.routes.message_routes import router

app = FastAPI(
    title="Nistula Guest Messaging API",
    version="1.0.0"
)

app.include_router(router)

@app.get("/")
def health_check():
    return {
        "status": "API running"
    }