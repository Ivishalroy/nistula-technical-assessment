-- Nistula Guest Messaging System
-- PostgreSQL Schema Design
-- =====================================================
-- Design Philosophy:
--   UUID primary keys throughout for distributed safety
--   Foreign key constraints enforce referential integrity
--   CHECK constraints encode business rules at the DB layer
--   Indexes target operational query patterns, not just lookups
-- =====================================================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- guests
-- Core identity record for each guest.
-- Intentionally lean — contact details (email, phone)
-- would live in a separate contact_methods table in
-- production to support multiple channels per guest.
-- =====================================================

CREATE TABLE guests (

    guest_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    guest_name VARCHAR(100) NOT NULL,

    primary_channel VARCHAR(50) NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- properties
-- Static reference data for each villa or property.
-- property_id is a human-readable slug (e.g. 'villa-b1')
-- rather than a UUID to simplify webhook payload matching
-- without a lookup join.
-- =====================================================

CREATE TABLE properties (

    property_id VARCHAR(50) PRIMARY KEY,

    property_name VARCHAR(100) NOT NULL,

    location VARCHAR(150) NOT NULL,

    bedrooms INTEGER NOT NULL,

    max_guests INTEGER NOT NULL,

    private_pool BOOLEAN DEFAULT FALSE,

    base_rate NUMERIC(10,2),

    check_in VARCHAR(20),

    check_out VARCHAR(20),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- reservations
-- Links a guest to a property for a specific stay.
-- booking_ref carries the external reference (e.g. NIS-2024-0891)
-- used to correlate incoming webhook messages to stays
-- without requiring the guest to know their internal UUID.
-- =====================================================

CREATE TABLE reservations (

    reservation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    booking_ref VARCHAR(100) UNIQUE NOT NULL,

    guest_id UUID NOT NULL,

    property_id VARCHAR(50) NOT NULL,

    check_in_date DATE,

    check_out_date DATE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (guest_id)
        REFERENCES guests(guest_id),

    FOREIGN KEY (property_id)
        REFERENCES properties(property_id)
);

-- =====================================================
-- conversations
-- Groups all messages for a single guest communication
-- thread. A guest may have multiple conversations across
-- separate stays or enquiries.
-- reservation_id is nullable to support pre-sales
-- conversations that exist before a booking is made.
-- =====================================================

CREATE TABLE conversations (

    conversation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    guest_id UUID NOT NULL,

    reservation_id UUID,

    property_id VARCHAR(50) NOT NULL,

    conversation_status VARCHAR(30)
    CHECK (
        conversation_status IN (
            'open',
            'resolved',
            'closed'
        )
    ) DEFAULT 'open',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (guest_id)
        REFERENCES guests(guest_id),

    FOREIGN KEY (reservation_id)
        REFERENCES reservations(reservation_id),

    FOREIGN KEY (property_id)
        REFERENCES properties(property_id)
);

-- =====================================================
-- messages
-- The core operational table. Each row represents one
-- inbound guest message and the AI system's output:
-- the drafted reply, confidence score, and routing action.
-- response_status tracks the lifecycle of the reply from
-- AI draft through to final delivery.
-- =====================================================

CREATE TABLE messages (

    message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    conversation_id UUID NOT NULL,

    source VARCHAR(50) NOT NULL,

    message_text TEXT NOT NULL,

    query_type VARCHAR(50) NOT NULL,

    drafted_reply TEXT,

    response_status VARCHAR(30) NOT NULL
    CHECK (
        response_status IN (
            'ai_drafted',
            'agent_edited',
            'auto_sent'
        )
    ),

    confidence_score NUMERIC(3,2) NOT NULL,

    action VARCHAR(30) NOT NULL
    CHECK (
        action IN (
            'auto_send',
            'agent_review',
            'escalate'
        )
    ),

    received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (conversation_id)
        REFERENCES conversations(conversation_id)
);

-- =====================================================
-- escalations
-- Created whenever the action engine routes a message
-- to 'escalate'. Tracks assignment, status, and
-- resolution. Separated from messages deliberately:
-- not every message escalates, and escalation lifecycle
-- (pending → in_review → resolved) is operationally
-- distinct from message lifecycle.
-- =====================================================

CREATE TABLE escalations (

    escalation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    message_id UUID NOT NULL,

    escalation_reason TEXT,

    escalation_status VARCHAR(30)
    CHECK (
        escalation_status IN (
            'pending',
            'in_review',
            'resolved'
        )
    ) DEFAULT 'pending',

    assigned_to VARCHAR(100),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (message_id)
        REFERENCES messages(message_id)
);

-- =====================================================
-- Indexes
-- Chosen to match actual query patterns in the workflow:
--   - query_type and action are filtered in analytics
--     and routing logic on every message processed
--   - escalation_status is polled by the SLA monitor
--   - booking_ref is the primary lookup key on inbound
--     webhook payloads
--   - property_id on escalations supports the pattern
--     detection query (complaints per property per window)
-- =====================================================

CREATE INDEX idx_messages_query_type
ON messages(query_type);

CREATE INDEX idx_messages_action
ON messages(action);

CREATE INDEX idx_escalations_status
ON escalations(escalation_status);