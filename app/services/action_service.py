def determine_action(
    confidence_score: float,
    query_type: str
):

    if query_type == "complaint":
        return "escalate"

    if confidence_score > 0.85:
        return "auto_send"

    if confidence_score >= 0.60:
        return "agent_review"

    return "escalate"