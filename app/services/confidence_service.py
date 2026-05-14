def calculate_confidence_score(
    query_type: str,
    message_text: str
):

    score = 0.50

    message_text = message_text.lower()

    # clear classification
    if query_type != "general_enquiry":
        score += 0.20

    # highly deterministic hospitality queries
    if query_type in [
        "pre_sales_availability",
        "pre_sales_pricing",
        "post_sales_checkin"
    ]:
        score += 0.10

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
    question_count = message_text.count("?")

    if question_count >= 2:
        score -= 0.35

    # complaints reduce confidence
    if query_type == "complaint":
        score -= 0.35

    # clamp between 0 and 1
    score = max(0.0, min(score, 1.0))

    return round(score, 2)