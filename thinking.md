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

---

## 9. Operational Scenario Analysis — Critical Hospitality Escalation, Villa B1, 3am

> **Scenario:** A guest at Villa B1 sends a WhatsApp message at 3am: *"There is no hot water and we have guests arriving for breakfast in 4 hours. This is unacceptable. I want a refund for tonight."* This is the third hot water complaint at Villa B1 in two months.

---

### Question A — The Immediate Response

**AI-generated message delivered to the guest:**

> "Hi, I'm very sorry you're experiencing this — especially so late at night and with guests arriving in the morning. I've marked this as an urgent issue and alerted the on-call support team immediately so they can assist as quickly as possible. We understand how disruptive this is, and a team member will follow up with you shortly regarding both the hot water issue and your concerns about tonight's stay."

**Reasoning:**

The response is governed by three operational principles. First, it leads with genuine empathy rather than process language, acknowledging the specific pressure the guest is under — overnight timing and imminent breakfast guests — rather than issuing a generic apology. Second, it makes a credible, bounded commitment: the on-call team has been alerted and will follow up, without over-promising a repair timeline or refund value that the AI cannot guarantee and that only a human agent can authoritatively confirm. Third, the tone is calm and direct. At 3am, a distressed guest with social obligations does not need corporate hedging — they need to know that someone is now responsible and acting. The phrasing "a team member will follow up shortly" is intentional: it transfers ownership to a human without abandoning the guest in the meantime.

---

### Question B — The Full System Response

Sending the AI reply is the first action, not the last. The platform should immediately trigger a coordinated operational response across four parallel tracks.

**1. Classification and Escalation Routing**

The classifier detects compound signals: complaint markers (`"unacceptable"`, `"refund"`), urgency markers (`"4 hours"`, `"guests arriving"`), and an active infrastructure failure. This combination forces a `complaint` classification with `severity: critical`. The confidence score is suppressed to a threshold that prevents `auto_send` under any circumstances — the action engine routes directly to `escalate`, bypassing `agent_review`. No AI-generated reply, however well-constructed, is appropriate as a terminal response for a critical infrastructure failure at 3am.

**2. Immediate Multi-Channel Notification**

An escalation record is written to the `escalations` table with the following fields populated at the point of creation:

- `property_id: villa-b1`
- `complaint_category: maintenance_hot_water`
- `severity: critical`
- `triggered_at: <timestamp>`
- `sla_deadline: triggered_at + 30 minutes`

Notifications fire simultaneously to the on-call property manager (push and SMS), the registered villa caretaker, and the operations escalation channel. Parallel notification — rather than sequential — ensures that a single point of contact failure does not delay the response.

**3. Comprehensive Event Logging**

The full event is written to the `messages` and `escalations` tables, including: the original guest message, the classification outcome, the confidence score, the escalation trigger reason, the drafted AI reply, the delivery timestamp, and the notification dispatch record for each recipient. This creates a complete auditable trail that supports any subsequent refund decision, liability assessment, or guest compensation review.

**4. 30-Minute SLA Enforcement and Breach Handling**

A response timer begins at the point of escalation creation. If no human agent marks the escalation as acknowledged within 30 minutes, the system executes two actions automatically:

- The escalation priority is elevated and a secondary alert fires to senior operations staff, explicitly flagged as `UNACKNOWLEDGED — SLA BREACH`.
- A follow-up message is delivered to the guest: *"We haven't forgotten you — our duty manager has been alerted and will be in contact with you very shortly."*

The guest-facing follow-up is operationally important. A guest who receives no further communication after the initial reply will reasonably assume the system has failed them. The automated follow-up maintains trust and demonstrates active monitoring without requiring human intervention at that precise moment.

The system continues issuing escalation alerts at defined intervals until a human agent explicitly acknowledges the incident. Unacknowledged escalations are marked as `sla_breached: true` in the `escalations` table for post-incident operational review.

---

### Question C — Pattern Detection and Prevention

Three complaints of the same category at the same property within 60 days is not a streak of bad luck — it is a systemic infrastructure signal. The platform should treat it as such.

**What the system should do with the pattern:**

The `escalations` table, indexed on `property_id` and `complaint_category`, provides the data required for pattern analysis. The system should maintain a rolling complaint frequency count per property per category. After the second occurrence, a `property_flag` record should be written against Villa B1, notifying the operations team of a potential recurring issue. By the third occurrence, that flag should be automatically promoted to a formal `property_issue_report`, routed to the operations lead rather than the on-call agent, and marked as requiring a scheduled maintenance review before the next guest check-in.

This distinction — between the on-call agent who handles the immediate incident and the operations team who owns the systemic problem — is architecturally significant. Routing all three complaints solely to the on-call channel ensures the pattern remains invisible at the operational level.

**What to build to prevent a fourth complaint:**

Two additions would close this loop permanently.

The first is a **property health monitor**: a scheduled background job that aggregates complaint categories by property over a configurable rolling window (default: 60 days). When the same complaint category crosses a defined threshold for a given property — for example, two or more occurrences — the monitor automatically generates a maintenance work order and flags the property in the database as requiring pre-arrival inspection. This flag is checked at the booking confirmation stage: any new check-in scheduled for a flagged property triggers an internal staff notification requesting verification that the reported system has been inspected and confirmed operational before the guest arrives. The guest never experiences the failure because the system identified and actioned it operationally.

The second is a **pre-arrival checklist integration**: a lightweight webhook triggered by booking confirmation events that, for flagged properties, dispatches a structured internal checklist to the assigned property staff. The checklist targets only the flagged complaint categories rather than a generic walk-through, making it fast to complete and directly relevant. This creates a mandatory human verification checkpoint between pattern detection and guest arrival with negligible architectural overhead.

**Long-term architecture direction:**

The underlying principle is that guest complaints are operational data, not merely support events. A platform that processes complaints in isolation — responding to each one without aggregating signal across incidents — is operationally reactive by design. The enhancements above shift the system toward proactive operational intelligence: complaints feed back into property management, maintenance scheduling, and check-in workflows, creating a closed loop between guest experience and infrastructure quality.

As the platform scales, this pattern detection capability can be extended into a recurring complaint analytics layer, surfacing property-level infrastructure trends, tracking resolution timelines, and benchmarking repeat incident frequency across the portfolio. The long-term goal is for the system to identify infrastructure risks before they reach the guest — converting reactive support capacity into a predictive operational asset.
