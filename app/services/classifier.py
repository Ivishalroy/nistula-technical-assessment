CLASSIFICATION_RULES = {
    "pre_sales_availability": [
        "available",
        "availability",
        "vacant",
        "dates"
    ],

    "pre_sales_pricing": [
        "price",
        "pricing",
        "rate",
        "cost"
    ],

    "post_sales_checkin": [
        "check-in",
        "check in",
        "wifi",
        "password"
    ],

    "special_request": [
        "early check-in",
        "airport transfer",
        "pickup",
        "chef"
    ],

    "complaint": [
        "not working",
        "bad",
        "unhappy",
        "refund",
        "issue",
        "problem"
    ]
}


def classify_query(message_text: str):

    message_text = message_text.lower()

    scores = {}

    for query_type, keywords in CLASSIFICATION_RULES.items():

        scores[query_type] = 0

        for keyword in keywords:

            if keyword in message_text:
                scores[query_type] += 1

    best_match = max(scores, key=scores.get)

    if scores[best_match] == 0:
        return "general_enquiry"

    return best_match