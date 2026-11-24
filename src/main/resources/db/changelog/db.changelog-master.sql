
--liquibase formatted sql

-- =========================================================
-- EVENTFLOW DATABASE CHANGELOG
-- Database: PostgreSQL 17
--
-- Project: EventFlow - Event Booking and Notification Platform
-- Author: amy-ojiakor-ojiakor
--
-- IMPORTANT:
-- This file contains the initial database schema.
-- Do not modify an already-applied changeset.
-- Add future database changes as new changesets.
-- =========================================================


-- =========================================================
-- CHANGESET 001: VENUES
-- Physical or virtual locations where events take place.
-- =========================================================

--changeset amy-ojiakor:001
CREATE TABLE venues (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--rollback DROP TABLE venues;


-- =========================================================
-- CHANGESET 002: USERS
-- Basic customer and event-organiser profiles.
-- Authentication is outside the initial scope.
-- =========================================================

--changeset amy-ojiakor:002
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone_number VARCHAR(30),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_users_email UNIQUE (email)
);

--rollback DROP TABLE users;


-- =========================================================
-- CHANGESET 003: EVENTS
-- Events belong to an organiser and take place at a venue.
-- Minimum deposit defaults to 30% of the booking total.
-- =========================================================

--changeset amy-ojiakor:003
CREATE TABLE events (
    id BIGSERIAL PRIMARY KEY,
    venue_id BIGINT NOT NULL REFERENCES venues(id),
    organizer_user_id BIGINT NOT NULL REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    event_date TIMESTAMPTZ NOT NULL,
    event_end_date TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    minimum_deposit_percentage NUMERIC(5,2) NOT NULL DEFAULT 30.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_event_status
        CHECK (
            status IN ('DRAFT', 'PUBLISHED', 'CANCELLED', 'COMPLETED')
        ),

    CONSTRAINT chk_event_deposit_percentage
        CHECK (
            minimum_deposit_percentage > 0
            AND minimum_deposit_percentage <= 100
        ),

    CONSTRAINT chk_event_dates
        CHECK (
            event_end_date IS NULL
            OR event_end_date > event_date
        )
);

CREATE INDEX idx_events_venue_id
    ON events(venue_id);

CREATE INDEX idx_events_organizer_user_id
    ON events(organizer_user_id);

CREATE INDEX idx_events_event_date
    ON events(event_date);

CREATE INDEX idx_events_status
    ON events(status);

--rollback DROP TABLE events;


-- =========================================================
-- CHANGESET 004: TICKET TYPES
-- An event can have multiple ticket categories.
--
-- Inventory:
-- total_quantity      = total available inventory
-- quantity_sold       = fully paid tickets/packages
-- quantity_reserved   = deposit-backed reservations
-- quantity_on_hold    = temporary checkout holds
--
-- Inventory invariant:
-- sold + reserved + on_hold <= total_quantity
-- =========================================================

--changeset amy-ojiakor:004
CREATE TABLE ticket_types (
    id BIGSERIAL PRIMARY KEY,
    event_id BIGINT NOT NULL REFERENCES events(id),
    name VARCHAR(150) NOT NULL,
    description TEXT,
    price NUMERIC(14,2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'NGN',
    total_quantity INTEGER NOT NULL,
    quantity_sold INTEGER NOT NULL DEFAULT 0,
    quantity_reserved INTEGER NOT NULL DEFAULT 0,
    quantity_on_hold INTEGER NOT NULL DEFAULT 0,
    sales_start_at TIMESTAMPTZ,
    sales_end_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_ticket_type_price
        CHECK (price >= 0),

    CONSTRAINT chk_ticket_type_total_quantity
        CHECK (total_quantity >= 0),

    CONSTRAINT chk_ticket_type_inventory
        CHECK (
            quantity_sold >= 0
            AND quantity_reserved >= 0
            AND quantity_on_hold >= 0
            AND quantity_sold
                + quantity_reserved
                + quantity_on_hold
                <= total_quantity
        ),

    CONSTRAINT chk_ticket_type_sales_period
        CHECK (
            sales_start_at IS NULL
            OR sales_end_at IS NULL
            OR sales_end_at > sales_start_at
        ),

    CONSTRAINT uq_ticket_type_event_name
        UNIQUE (event_id, name)
);

CREATE INDEX idx_ticket_types_event_id
    ON ticket_types(event_id);

--rollback DROP TABLE ticket_types;


-- =========================================================
-- CHANGESET 005: CHECKOUT HOLDS
-- Temporary inventory holds while a customer completes
-- checkout. These are not deposit-backed bookings.
--
-- Example: a 10-minute checkout hold.
-- =========================================================

--changeset amy-ojiakor:005
CREATE TABLE checkout_holds (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    hold_reference VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_checkout_hold_reference
        UNIQUE (hold_reference),

    CONSTRAINT chk_checkout_hold_status
        CHECK (
            status IN ('ACTIVE', 'CONVERTED', 'EXPIRED', 'CANCELLED')
        )
);

CREATE INDEX idx_checkout_holds_user_id
    ON checkout_holds(user_id);

CREATE INDEX idx_checkout_holds_status_expiry
    ON checkout_holds(status, expires_at);

--rollback DROP TABLE checkout_holds;


-- =========================================================
-- CHANGESET 006: CHECKOUT HOLD ITEMS
-- Stores the ticket categories, quantities and prices
-- temporarily held during checkout.
-- =========================================================

--changeset amy-ojiakor:006
CREATE TABLE checkout_hold_items (
    id BIGSERIAL PRIMARY KEY,
    checkout_hold_id BIGINT NOT NULL
        REFERENCES checkout_holds(id) ON DELETE CASCADE,
    ticket_type_id BIGINT NOT NULL REFERENCES ticket_types(id),
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(14,2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'NGN',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_checkout_hold_item_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_checkout_hold_item_price
        CHECK (unit_price >= 0),

    CONSTRAINT uq_checkout_hold_ticket_type
        UNIQUE (checkout_hold_id, ticket_type_id)
);

CREATE INDEX idx_checkout_hold_items_ticket_type_id
    ON checkout_hold_items(ticket_type_id);

--rollback DROP TABLE checkout_hold_items;


-- =========================================================
-- CHANGESET 007: BOOKINGS
-- A booking is initially created in PENDING_DEPOSIT state.
--
-- After the backend verifies a successful qualifying payment:
-- PENDING_DEPOSIT -> RESERVED
--
-- After the full booking amount has been paid:
-- RESERVED -> CONFIRMED
--
-- A booking can also expire or be cancelled.
-- =========================================================

--changeset amy-ojiakor:007
CREATE TABLE bookings (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    event_id BIGINT NOT NULL REFERENCES events(id),
    checkout_hold_id BIGINT UNIQUE REFERENCES checkout_holds(id),
    booking_reference VARCHAR(100) NOT NULL,
    total_amount NUMERIC(14,2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'NGN',
    minimum_deposit_percentage NUMERIC(5,2) NOT NULL,
    minimum_deposit_amount NUMERIC(14,2) NOT NULL,
    status VARCHAR(25) NOT NULL DEFAULT 'PENDING_DEPOSIT',
    reserved_at TIMESTAMPTZ,
    payment_due_at TIMESTAMPTZ,
    confirmed_at TIMESTAMPTZ,
    expired_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_booking_reference
        UNIQUE (booking_reference),

    CONSTRAINT chk_booking_total_amount
        CHECK (total_amount > 0),

    CONSTRAINT chk_booking_deposit_percentage
        CHECK (
            minimum_deposit_percentage > 0
            AND minimum_deposit_percentage <= 100
        ),

    CONSTRAINT chk_booking_deposit_amount
        CHECK (
            minimum_deposit_amount > 0
            AND minimum_deposit_amount <= total_amount
        ),

    CONSTRAINT chk_booking_status
        CHECK (
            status IN (
                'PENDING_DEPOSIT',
                'RESERVED',
                'CONFIRMED',
                'EXPIRED',
                'CANCELLED'
            )
        ),

    CONSTRAINT chk_booking_payment_deadline
        CHECK (
            payment_due_at IS NULL
            OR reserved_at IS NULL
            OR payment_due_at > reserved_at
        )
);

CREATE INDEX idx_bookings_user_id
    ON bookings(user_id);

CREATE INDEX idx_bookings_event_id
    ON bookings(event_id);

CREATE INDEX idx_bookings_status_payment_due
    ON bookings(status, payment_due_at);

--rollback DROP TABLE bookings;


-- =========================================================
-- CHANGESET 008: BOOKING ITEMS
-- Resolves the many-to-many relationship between bookings
-- and ticket types.
--
-- A booking can contain multiple ticket categories.
-- Unit price is captured at booking time.
-- Line total = quantity * unit_price.
-- =========================================================

--changeset amy-ojiakor:008
CREATE TABLE booking_items (
    id BIGSERIAL PRIMARY KEY,
    booking_id BIGINT NOT NULL
        REFERENCES bookings(id),
    ticket_type_id BIGINT NOT NULL
        REFERENCES ticket_types(id),
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(14,2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'NGN',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_booking_item_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_booking_item_unit_price
        CHECK (unit_price >= 0),

    CONSTRAINT uq_booking_ticket_type
        UNIQUE (booking_id, ticket_type_id)
);

CREATE INDEX idx_booking_items_ticket_type_id
    ON booking_items(ticket_type_id);

--rollback DROP TABLE booking_items;


-- =========================================================
-- CHANGESET 009: PAYMENTS
-- A booking can have multiple payment transactions.
-- This supports deposits and instalment payments.
--
-- Only SUCCESSFUL payments count towards the amount paid.
-- =========================================================

--changeset amy-ojiakor:009
CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,
    booking_id BIGINT NOT NULL REFERENCES bookings(id),
    payment_reference VARCHAR(100) NOT NULL,
    provider_reference VARCHAR(150),
    idempotency_key VARCHAR(150),
    payment_provider VARCHAR(100),
    payment_method VARCHAR(50),
    amount NUMERIC(14,2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'NGN',
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    successful_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_payment_reference
        UNIQUE (payment_reference),

    CONSTRAINT uq_payment_provider_reference
        UNIQUE (provider_reference),

    CONSTRAINT uq_payment_idempotency_key
        UNIQUE (idempotency_key),

    CONSTRAINT chk_payment_amount
        CHECK (amount > 0),

    CONSTRAINT chk_payment_status
        CHECK (
            status IN (
                'PENDING',
                'SUCCESSFUL',
                'FAILED',
                'CANCELLED'
            )
        )
);

CREATE INDEX idx_payments_booking_id
    ON payments(booking_id);

CREATE INDEX idx_payments_status
    ON payments(status);

--rollback DROP TABLE payments;


-- =========================================================
-- CHANGESET 010: NOTIFICATIONS
-- Stores notifications to be sent to customers.
-- Supports email, SMS and in-app notifications.
-- =========================================================

--changeset amy-ojiakor:010
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    booking_id BIGINT NOT NULL REFERENCES bookings(id),
    user_id BIGINT NOT NULL REFERENCES users(id),
    notification_type VARCHAR(100) NOT NULL,
    channel VARCHAR(20) NOT NULL,
    recipient VARCHAR(255) NOT NULL,
    subject VARCHAR(255),
    message TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    attempt_count INTEGER NOT NULL DEFAULT 0,
    scheduled_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    last_error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_notification_channel
        CHECK (channel IN ('EMAIL', 'SMS', 'IN_APP')),

    CONSTRAINT chk_notification_status
        CHECK (status IN ('PENDING', 'SENT', 'FAILED')),

    CONSTRAINT chk_notification_attempt_count
        CHECK (attempt_count >= 0)
);

CREATE INDEX idx_notifications_booking_id
    ON notifications(booking_id);

CREATE INDEX idx_notifications_user_id
    ON notifications(user_id);

CREATE INDEX idx_notifications_status_scheduled
    ON notifications(status, scheduled_at);

--rollback DROP TABLE notifications;


-- =========================================================
-- CHANGESET 011: OUTBOX EVENTS
-- Stores domain events in the same database transaction
-- as the corresponding business operation.
--
-- A separate publisher will publish these events to Kafka.
-- =========================================================

--changeset amy-ojiakor:011
CREATE TABLE outbox_events (
    id BIGSERIAL PRIMARY KEY,
    aggregate_type VARCHAR(100) NOT NULL,
    aggregate_id BIGINT NOT NULL,
    event_type VARCHAR(150) NOT NULL,
    payload JSONB NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    attempts INTEGER NOT NULL DEFAULT 0,
    next_attempt_at TIMESTAMPTZ,
    published_at TIMESTAMPTZ,
    last_error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_outbox_event_status
        CHECK (
            status IN ('PENDING', 'PUBLISHED', 'FAILED')
        ),

    CONSTRAINT chk_outbox_event_attempts
        CHECK (attempts >= 0)
);

CREATE INDEX idx_outbox_events_status_created
    ON outbox_events(status, created_at);

CREATE INDEX idx_outbox_events_next_attempt
    ON outbox_events(next_attempt_at);

--rollback DROP TABLE outbox_events;
