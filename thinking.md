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

## 6. Future Scaling Considerations

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

## 7. Tradeoffs and Assumptions

Several intentional tradeoffs were made during implementation:

- Rule-based classification was preferred over ML classification for simplicity and reliability.
- AI-generated confidence scores were avoided in favor of deterministic scoring.
- The property dataset was hardcoded for simplicity since persistent storage was outside scope.
- Authentication and deployment infrastructure were excluded to maintain focus on backend workflow quality.
- The schema design prioritized readability and operational clarity over enterprise-level complexity.

These decisions were made to balance realism, maintainability, and assessment scope constraints.


## 8. Written answers

## Database Schema Design Decisions 
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

### Lean Guest Profile Design
The `guests` table was intentionally kept simple. Contact details such as phone numbers or emails were not added because the assessment focused mainly on unified guest identity and messaging workflows. In a larger production system, these would likely exist in a separate contact management table to support multiple communication channels for the same guest. For this implementation, `primary_channel` captures the essential requirement cleanly without unnecessary complexity.

### Human-Readable Property IDs
The `property_id` field uses readable values such as `villa-b1` instead of UUIDs. Since inbound webhook payloads already contain property identifiers in this format, using them directly simplifies backend lookups and avoids extra translation logic between external and internal identifiers. This keeps the API workflow simpler and easier to trace during debugging.

### Nullable Reservation Link in Conversations
The `reservation_id` field in the `conversations` table was intentionally kept nullable. Not every guest interaction starts after a booking exists. Guests may first ask about pricing, availability, or amenities before making a reservation. Allowing conversations without a reservation link helps the schema model both pre-sales and post-booking communication realistically.

### Separate Escalations Table
Escalations were modeled in a separate table instead of being merged directly into the `messages` table. Most messages never escalate, so storing escalation-specific fields inside every message row would create unnecessary NULL values and reduce clarity. Separating escalations also better reflects the operational workflow, where escalations have their own lifecycle including assignment, review, and resolution.

### Confidence Score Validation
The `confidence_score` field includes database-level validation to ensure values remain between 0 and 1. Although validation already exists in the backend application layer, adding constraints at the database level improves data integrity and prevents invalid records from being stored accidentally.

# Hardest Design Decision
The hardest design decision was determining whether escalation handling should exist directly inside the `messages` table or as a separate relational table. Initially, keeping everything inside `messages` seemed simpler because it reduced joins and relationships. However, after thinking through the operational workflow more carefully, it became clear that escalations behave differently from standard messages.
A message represents a single communication event, while an escalation represents an ongoing operational process involving assignment, review, tracking, and resolution. Keeping escalation data separate made the schema cleaner, reduced unnecessary NULL fields for non-escalated messages, and allowed the escalation workflow to evolve independently from the core messaging system. Although this introduces an additional relationship, the resulting structure is more organized and scalable.

## PART-3 THINKING QUESTION
Operational Scenario Analysis — Critical Hospitality Escalation
Scenario: A guest at Villa B1 sends a WhatsApp message at 3am:

> “There is no hot water and we have guests arriving for breakfast in 4 hours. This is unacceptable. I want a refund for tonight.”

This is the third hot water complaint at Villa B1 in two months.

---

## A. Immediate Guest Response

### AI-Generated Reply

> “Hi, I’m very sorry you’re facing this issue, especially so late at night and with guests arriving in the morning. I’ve marked this as urgent and alerted the support team immediately so they can assist as quickly as possible. A team member will follow up with you shortly regarding both the hot water issue and your concerns about tonight’s stay.”

### Reasoning

The response is designed to:
- acknowledge the guest’s frustration clearly
- avoid sounding robotic or overly formal
- communicate urgency without making unrealistic promises

The AI does not promise a refund or repair timeline because those decisions should be handled by human staff. Instead, the message reassures the guest that the issue has been escalated and ownership has been transferred to the operations team.

---

## B. Full System Response

The AI reply is only the first step. The platform should trigger additional operational workflows immediately.

### 1. Classification and Escalation

The system detects:
- complaint language
- urgency indicators
- infrastructure failure signals

This results in:
- `query_type = complaint`
- `severity = critical`
- `action = escalate`

The message bypasses normal review flows and is escalated directly to human staff.

---

### 2. Operational Notifications

An escalation record is created in the database with:
- property ID
- complaint category
- severity
- timestamps
- SLA deadline

Notifications are then sent to:
- on-call support staff
- property caretaker
- operations escalation channel

Using parallel notifications reduces the risk of delayed response if one contact is unavailable.

---

### 3. Event Logging

The system stores:
- the original guest message
- AI-generated reply
- confidence score
- escalation reason
- timestamps
- notification records

This creates a complete operational audit trail that can later support:
- refund decisions
- internal review
- incident analysis

---

### 4. SLA Monitoring

A response timer begins once the escalation is created.

If no staff member acknowledges the escalation within 30 minutes:
- escalation priority increases
- senior operations staff are alerted
- the guest receives a follow-up reassurance message

This prevents the guest from feeling ignored during a high-stress situation.

---

## C. Pattern Detection and Prevention

Three complaints about the same issue at the same property within two months suggests a recurring operational problem rather than an isolated incident.

### Recommended System Behavior

The platform should track complaint frequency by:
- property
- complaint category
- time window

After repeated incidents:
- the property should be flagged internally
- operations staff should receive maintenance alerts
- pre-arrival inspections should be triggered automatically before future guest check-ins

---

## Future Improvement Ideas

Two useful future improvements would be:

### 1. Property Health Monitoring

A scheduled monitoring process could track recurring complaint categories across properties and automatically generate maintenance alerts when thresholds are exceeded.

---

### 2. Pre-Arrival Checklist Integration

For flagged properties, the system could trigger an internal checklist before guest arrival to verify that previously reported issues have been resolved.

---

## Long-Term Direction

The long-term goal is to treat guest complaints not only as support tickets, but also as operational signals.

Instead of reacting to incidents individually, the platform should gradually evolve toward identifying infrastructure risks proactively and helping operations teams resolve issues before they impact future guests.

# Conclusion

The implementation focuses on building a clean and operationally realistic AI-assisted guest messaging backend rather than maximizing feature complexity.

The final system emphasizes:
- modular backend architecture
- explainable classification logic
- operational escalation handling
- AI safety through confidence-based routing
- maintainable database design
- resilience to AI provider failures

The overall goal was to design a backend system that feels practical, scalable, and production-aware while remaining appropriately scoped for the assessment.