from anthropic import Anthropic

from app.config.settings import (
    ANTHROPIC_API_KEY,
    CLAUDE_MODEL
)

client = Anthropic(
    api_key=ANTHROPIC_API_KEY
)


def generate_guest_reply(prompt: str):

    try:

        response = client.messages.create(
            model=CLAUDE_MODEL,
            max_tokens=300,
            temperature=0.3,
            messages=[
                {
                    "role": "user",
                    "content": prompt
                }
            ]
        )

        drafted_reply = response.content[0].text

        return drafted_reply

    except Exception as error:

        print("CLAUDE API ERROR:")
        print(error)

        return (
            "Thank you for your message. "
            "Our team will review your request and get back to you shortly."
        )