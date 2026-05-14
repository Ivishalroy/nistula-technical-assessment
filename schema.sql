-- =====================================================
-- Nistula Guest Messaging System Database Schema
-- PostgreSQL Schema Design
-- =====================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- Guests Table
-- Stores guest identity information
-- =====================================================

CREATE TABLE guests (

    guest_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    guest_name VARCHAR(100) NOT NULL,

    primary_channel VARCHAR(50) NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- Properties Table
-- Stores property/villa information
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
-- Conversations Table
-- Groups guest communication threads
-- =====================================================

CREATE TABLE conversations (

    conversation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    guest_id UUID NOT NULL,

    property_id VARCHAR(50) NOT NULL,

    booking_ref VARCHAR(100),

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

    FOREIGN KEY (property_id)
        REFERENCES properties(property_id)
);

-- =====================================================
-- Messages Table
-- Stores guest messages and AI outputs
-- =====================================================

CREATE TABLE messages (

    message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    conversation_id UUID NOT NULL,

    source VARCHAR(50) NOT NULL,

    message_text TEXT NOT NULL,

    query_type VARCHAR(50),

    drafted_reply TEXT,

    confidence_score NUMERIC(3,2),

    action VARCHAR(30)
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
-- Escalations Table
-- Tracks messages requiring human intervention
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
-- =====================================================

CREATE INDEX idx_messages_query_type
ON messages(query_type);

CREATE INDEX idx_messages_action
ON messages(action);

CREATE INDEX idx_escalations_status
ON escalations(escalation_status);