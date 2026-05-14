# Nistula Guest Messaging System — Engineering Notes

This document outlines the architectural decisions, tradeoffs, assumptions, and operational reasoning behind the implementation of the AI-powered guest messaging backend system.

The goal of the system was not only to generate AI responses, but to design a backend workflow that is modular, reliable, explainable, and operationally practical for hospitality communication use cases.

## 1. Backend Architecture Decisions

The system was designed using a modular service-oriented structure to separate responsibilities clearly across the application.

Core backend layers include:

- Request validation layer
- Message normalization layer
- Query classification engine
- Prompt generation layer
- Claude AI integration service
- Confidence scoring engine
- Action/escalation decision engine

This separation improves maintainability, readability, and future scalability.

FastAPI was selected because of:
- built-in request validation
- automatic OpenAPI documentation
- strong typing support
- clean integration with Pydantic models

The architecture intentionally avoids unnecessary complexity such as queues, vector databases, or orchestration frameworks since the assessment scope did not require them.

## 2. Query Classification Strategy

A deterministic rule-based classification engine was implemented instead of using AI-based classification.

The reasoning behind this decision was:
- predictable behavior
- easier debugging
- explainable logic
- lower operational cost
- reduced hallucination risk

The classifier uses keyword matching to categorize guest messages into:
- pre_sales_availability
- pre_sales_pricing
- post_sales_checkin
- special_request
- complaint
- general_enquiry

This approach is lightweight, reliable, and appropriate for the constrained problem scope of the assessment.

## 3. Confidence Scoring Design

Confidence scores are calculated using deterministic heuristics instead of model-generated confidence values.

The scoring system considers:
- query clarity
- classification certainty
- deterministic hospitality intents
- ambiguity from multiple questions
- complaint severity

Example scoring behavior:
- availability and pricing queries receive higher confidence
- complaint messages reduce confidence significantly
- multi-intent messages reduce confidence due to ambiguity

The scoring system was intentionally designed to remain explainable and auditable.

## 4. Escalation and Action Logic

The action engine determines whether a response should:
- auto_send
- agent_review
- escalate

This decision is based on both:
- confidence score
- operational risk

Examples:
- complaints always escalate
- high-confidence deterministic queries are auto-sent
- ambiguous multi-question requests are routed for human review

This separation between AI generation and business decision logic was intentional to preserve operational control and reliability.

## 5. AI Failure Handling

The system includes graceful fallback handling for AI provider failures.

If the Claude API fails due to:
- authentication issues
- rate limits
- outages
- unexpected exceptions

the backend still returns a structured response with a safe fallback message.

This prevents total API failure and improves system resilience.

## 6. Database Schema Design

The PostgreSQL schema was designed to model the operational workflow of a hospitality messaging platform.

Core entities include:
- guests
- properties
- conversations
- messages
- escalations

The schema uses:
- UUID primary keys
- foreign key relationships
- validation constraints
- operational indexing

The design intentionally avoids overengineering while still preserving normalization and scalability principles.

## 7. Future Scaling Considerations

If the platform scaled to production usage, future improvements could include:
- asynchronous task queues
- Redis caching
- conversation memory
- multilingual support
- analytics dashboards
- staff management systems
- retrieval-augmented generation (RAG)
- centralized logging and monitoring

These features were intentionally excluded to keep the implementation aligned with the assessment scope.

## 8. Tradeoffs and Assumptions

Several intentional tradeoffs were made during implementation:

- Rule-based classification was preferred over ML classification for simplicity and reliability.
- AI-generated confidence scores were avoided in favor of deterministic scoring.
- The property dataset was hardcoded for simplicity since persistent storage was outside scope.
- Authentication and deployment infrastructure were excluded to maintain focus on backend workflow quality.
- The schema design prioritized readability and operational clarity over enterprise-level complexity.

These decisions were made to balance realism, maintainability, and assessment scope constraints.

## Conclusion

The implementation focuses on building a clean and operationally realistic AI-assisted guest messaging backend rather than maximizing feature complexity.

The final system emphasizes:
- modular architecture
- explainable logic
- operational escalation handling
- resilience to AI failures
- maintainable backend design

The overall goal was to design a backend system that feels practical, scalable, and production-aware while remaining appropriately scoped for the assessment.

