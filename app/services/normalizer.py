import uuid


def normalize_message(payload):

    normalized_data = {
        "message_id": str(uuid.uuid4()),
        "source": payload.source,
        "guest_name": payload.guest_name,
        "message_text": payload.message,
        "timestamp": payload.timestamp,
        "booking_ref": payload.booking_ref,
        "property_id": payload.property_id
    }

    return normalized_data