-- =====================================================
-- Database Schema for Data Archival Platform
-- PostgreSQL 15+
-- =====================================================

-- Table: application_logs
-- Stores application log entries (simulated source data)
CREATE TABLE IF NOT EXISTS application_logs (
    id           BIGSERIAL PRIMARY KEY,
    level        VARCHAR(10)  NOT NULL DEFAULT 'INFO',
    message      TEXT         NOT NULL,
    source       VARCHAR(255) NOT NULL,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    archived     BOOLEAN      NOT NULL DEFAULT FALSE,
    archived_at  TIMESTAMPTZ
);

CREATE INDEX idx_logs_cold ON application_logs (created_at, archived)
    WHERE archived = FALSE;

-- Table: invoices
-- Stores invoice records (simulated source data)
CREATE TABLE IF NOT EXISTS invoices (
    id              BIGSERIAL PRIMARY KEY,
    invoice_number  VARCHAR(50)    NOT NULL UNIQUE,
    client_name     VARCHAR(255)   NOT NULL,
    amount          DECIMAL(12, 2) NOT NULL,
    currency        VARCHAR(3)     NOT NULL DEFAULT 'EUR',
    issued_at       TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    paid_at         TIMESTAMPTZ,
    archived        BOOLEAN        NOT NULL DEFAULT FALSE,
    archived_at     TIMESTAMPTZ
);

CREATE INDEX idx_invoices_cold ON invoices (issued_at, archived)
    WHERE archived = FALSE;

-- =====================================================
-- Seed Data (for demo/testing)
-- =====================================================

-- Insert old logs (> 90 days old — will be archived)
INSERT INTO application_logs (level, message, source, created_at) VALUES
    ('INFO',  'User login successful',          'auth-service',    NOW() - INTERVAL '120 days'),
    ('WARN',  'High memory usage detected',     'monitor-service', NOW() - INTERVAL '150 days'),
    ('ERROR', 'Payment gateway timeout',        'billing-service', NOW() - INTERVAL '200 days'),
    ('INFO',  'Batch processing completed',     'batch-service',   NOW() - INTERVAL '180 days'),
    ('DEBUG', 'Cache invalidated',              'cache-service',   NOW() - INTERVAL '100 days');

-- Insert recent logs (< 90 days — will NOT be archived)
INSERT INTO application_logs (level, message, source, created_at) VALUES
    ('INFO',  'New deployment started',         'deploy-service',  NOW() - INTERVAL '10 days'),
    ('ERROR', 'Database connection pool full',  'api-service',     NOW() - INTERVAL '5 days');

-- Insert old invoices (> 90 days — will be archived)
INSERT INTO invoices (invoice_number, client_name, amount, currency, issued_at, paid_at) VALUES
    ('INV-2024-001', 'Acme Corp',       1500.00, 'EUR', NOW() - INTERVAL '200 days', NOW() - INTERVAL '190 days'),
    ('INV-2024-002', 'GlobalTech SAS',  3200.50, 'EUR', NOW() - INTERVAL '150 days', NOW() - INTERVAL '140 days'),
    ('INV-2024-003', 'StartupXYZ',       750.00, 'USD', NOW() - INTERVAL '120 days', NULL);

-- Insert recent invoices (< 90 days — will NOT be archived)
INSERT INTO invoices (invoice_number, client_name, amount, currency, issued_at) VALUES
    ('INV-2025-010', 'CloudFirst Inc',  5000.00, 'EUR', NOW() - INTERVAL '15 days'),
    ('INV-2025-011', 'DataDriven SA',   2100.00, 'EUR', NOW() - INTERVAL '3 days');
