def determine_action(
    confidence_score: float,
    query_type: str,
    message_text: str
):

    # complaints always escalate
    if query_type == "complaint":
        return "escalate"

    # multiple questions require human review
    if message_text.count("?") >= 2:
        return "agent_review"

    # high confidence safe auto-send
    if confidence_score >= 0.85:
        return "auto_send"

    # medium confidence human review
    if confidence_score >= 0.60:
        return "agent_review"

    # low confidence escalate
    return "escalate"