def calculate_confidence_score(
    query_type: str,
    message_text: str
):

    score = 0.50

    message_text = message_text.lower()

    # clear classification
    if query_type != "general_enquiry":
        score += 0.20

    # strong keyword confidence
    if any(word in message_text for word in [
        "available",
        "price",
        "rate",
        "wifi",
        "check-in",
        "refund"
    ]):
        score += 0.15

    # multiple questions reduce certainty
    if "?" in message_text and len(message_text.split("?")) > 2:
        score -= 0.10

    # complaints reduce confidence
    if query_type == "complaint":
        score -= 0.35

    # clamp between 0 and 1
    score = max(0.0, min(score, 1.0))

    return round(score, 2)