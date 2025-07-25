-- ISMAIL Platform - Schéma Supabase
-- Base de données PostgreSQL optimisée pour l'Afrique de l'Ouest

-- =====================================================
-- EXTENSIONS
-- =====================================================

-- Activer les extensions nécessaires
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- =====================================================
-- SCHÉMA ISMAIL
-- =====================================================

-- Créer le schéma principal
CREATE SCHEMA IF NOT EXISTS ismail;

-- =====================================================
-- ÉNUMÉRATIONS
-- =====================================================

-- Types de profils utilisateur
CREATE TYPE ismail.profile_type AS ENUM (
    'CLIENT',
    'PARTNER', 
    'COMMERCIAL',
    'ADMIN'
);

-- Statuts KYC
CREATE TYPE ismail.kyc_status AS ENUM (
    'PENDING',
    'IN_PROGRESS',
    'APPROVED',
    'REJECTED',
    'EXPIRED'
);

-- Statuts génériques
CREATE TYPE ismail.status AS ENUM (
    'ACTIVE',
    'INACTIVE',
    'SUSPENDED',
    'DELETED'
);

-- Types de transactions
CREATE TYPE ismail.transaction_type AS ENUM (
    'DEPOSIT',
    'WITHDRAWAL',
    'TRANSFER',
    'PAYMENT',
    'COMMISSION',
    'REFUND',
    'FEE'
);

-- Statuts de transaction
CREATE TYPE ismail.transaction_status AS ENUM (
    'PENDING',
    'PROCESSING',
    'COMPLETED',
    'FAILED',
    'CANCELLED',
    'REFUNDED'
);

-- Devises supportées
CREATE TYPE ismail.currency AS ENUM (
    'XOF',  -- Franc CFA Ouest
    'XAF',  -- Franc CFA Central
    'GHS',  -- Cedi Ghana
    'NGN',  -- Naira Nigeria
    'EUR',  -- Euro
    'USD'   -- Dollar US
);

-- Moyens de paiement
CREATE TYPE ismail.payment_method AS ENUM (
    'ORANGE_MONEY',
    'MTN_MOMO',
    'WAVE',
    'CINETPAY',
    'BANK_CARD',
    'BANK_TRANSFER',
    'CASH'
);

-- =====================================================
-- TABLE UTILISATEURS
-- =====================================================

CREATE TABLE ismail.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Identifiant unique ISMAIL
    ismail_id VARCHAR(20) UNIQUE NOT NULL,
    
    -- Informations personnelles
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    gender VARCHAR(10),
    
    -- Adresse
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state_region VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(2) NOT NULL DEFAULT 'CI', -- Code ISO pays
    
    -- Profil et statut
    profile_type ismail.profile_type NOT NULL DEFAULT 'CLIENT',
    status ismail.status NOT NULL DEFAULT 'ACTIVE',
    kyc_status ismail.kyc_status NOT NULL DEFAULT 'PENDING',
    
    -- Sécurité
    password_hash VARCHAR(255),
    pin_hash VARCHAR(255),
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(255),
    
    -- Biométrie
    biometric_data JSONB,
    face_template BYTEA,
    fingerprint_template BYTEA,
    
    -- Préférences
    language VARCHAR(5) DEFAULT 'fr',
    timezone VARCHAR(50) DEFAULT 'Africa/Abidjan',
    currency ismail.currency DEFAULT 'XOF',
    
    -- Métadonnées
    metadata JSONB DEFAULT '{}',
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE,
    email_verified_at TIMESTAMP WITH TIME ZONE,
    phone_verified_at TIMESTAMP WITH TIME ZONE,
    
    -- Contraintes
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT valid_phone CHECK (phone ~* '^\+[1-9]\d{1,14}$'),
    CONSTRAINT valid_country CHECK (LENGTH(country) = 2)
);

-- =====================================================
-- TABLE PORTEFEUILLES
-- =====================================================

CREATE TABLE ismail.wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Référence utilisateur
    user_id UUID NOT NULL REFERENCES ismail.users(id) ON DELETE CASCADE,
    
    -- Informations portefeuille
    balance DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    currency ismail.currency NOT NULL DEFAULT 'XOF',
    
    -- Limites
    daily_limit DECIMAL(15,2) DEFAULT 500000.00, -- 500k XOF par défaut
    monthly_limit DECIMAL(15,2) DEFAULT 5000000.00, -- 5M XOF par défaut
    
    -- Statut
    status ismail.status NOT NULL DEFAULT 'ACTIVE',
    
    -- Métadonnées
    metadata JSONB DEFAULT '{}',
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Contraintes
    CONSTRAINT positive_balance CHECK (balance >= 0),
    CONSTRAINT positive_limits CHECK (daily_limit >= 0 AND monthly_limit >= 0),
    CONSTRAINT unique_user_currency UNIQUE (user_id, currency)
);

-- =====================================================
-- TABLE TRANSACTIONS
-- =====================================================

CREATE TABLE ismail.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Référence portefeuille
    wallet_id UUID NOT NULL REFERENCES ismail.wallets(id),
    
    -- Informations transaction
    type ismail.transaction_type NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    currency ismail.currency NOT NULL,
    
    -- Statut et référence
    status ismail.transaction_status NOT NULL DEFAULT 'PENDING',
    reference VARCHAR(100) UNIQUE NOT NULL,
    external_reference VARCHAR(255),
    
    -- Description et métadonnées
    description TEXT,
    metadata JSONB DEFAULT '{}',
    
    -- Paiement
    payment_method ismail.payment_method,
    payment_provider VARCHAR(50),
    payment_reference VARCHAR(255),
    
    -- Frais
    fee_amount DECIMAL(15,2) DEFAULT 0.00,
    fee_currency ismail.currency,
    
    -- Soldes avant/après
    balance_before DECIMAL(15,2),
    balance_after DECIMAL(15,2),
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Contraintes
    CONSTRAINT positive_amount CHECK (amount > 0),
    CONSTRAINT positive_fee CHECK (fee_amount >= 0)
);

-- =====================================================
-- TABLE SESSIONS
-- =====================================================

CREATE TABLE ismail.user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Référence utilisateur
    user_id UUID NOT NULL REFERENCES ismail.users(id) ON DELETE CASCADE,
    
    -- Informations session
    token_hash VARCHAR(255) NOT NULL,
    refresh_token_hash VARCHAR(255),
    
    -- Appareil et localisation
    device_info JSONB,
    ip_address INET,
    user_agent TEXT,
    location JSONB,
    
    -- Validité
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Statut
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Contraintes
    CONSTRAINT future_expiry CHECK (expires_at > created_at)
);

-- =====================================================
-- TABLE CARTES PROFESSIONNELLES
-- =====================================================

CREATE TABLE ismail.professional_cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Référence utilisateur
    user_id UUID NOT NULL REFERENCES ismail.users(id) ON DELETE CASCADE,
    
    -- Informations carte
    card_number VARCHAR(20) UNIQUE NOT NULL,
    qr_code_data TEXT NOT NULL,
    
    -- Validité
    issued_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Métadonnées
    metadata JSONB DEFAULT '{}',
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Contraintes
    CONSTRAINT unique_active_card_per_user UNIQUE (user_id, is_active) 
        DEFERRABLE INITIALLY DEFERRED
);

-- =====================================================
-- TABLE AUDIT LOGS
-- =====================================================

CREATE TABLE ismail.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Référence utilisateur (optionnel)
    user_id UUID REFERENCES ismail.users(id),
    
    -- Action
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID,
    
    -- Détails
    old_values JSONB,
    new_values JSONB,
    
    -- Contexte
    ip_address INET,
    user_agent TEXT,
    session_id UUID,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- INDEX POUR PERFORMANCE
-- =====================================================

-- Index utilisateurs
CREATE INDEX idx_users_ismail_id ON ismail.users(ismail_id);
CREATE INDEX idx_users_email ON ismail.users(email);
CREATE INDEX idx_users_phone ON ismail.users(phone);
CREATE INDEX idx_users_profile_type ON ismail.users(profile_type);
CREATE INDEX idx_users_status ON ismail.users(status);
CREATE INDEX idx_users_kyc_status ON ismail.users(kyc_status);
CREATE INDEX idx_users_country ON ismail.users(country);
CREATE INDEX idx_users_created_at ON ismail.users(created_at);

-- Index portefeuilles
CREATE INDEX idx_wallets_user_id ON ismail.wallets(user_id);
CREATE INDEX idx_wallets_currency ON ismail.wallets(currency);
CREATE INDEX idx_wallets_status ON ismail.wallets(status);

-- Index transactions
CREATE INDEX idx_transactions_wallet_id ON ismail.transactions(wallet_id);
CREATE INDEX idx_transactions_type ON ismail.transactions(type);
CREATE INDEX idx_transactions_status ON ismail.transactions(status);
CREATE INDEX idx_transactions_reference ON ismail.transactions(reference);
CREATE INDEX idx_transactions_payment_method ON ismail.transactions(payment_method);
CREATE INDEX idx_transactions_created_at ON ismail.transactions(created_at);
CREATE INDEX idx_transactions_amount ON ismail.transactions(amount);

-- Index sessions
CREATE INDEX idx_sessions_user_id ON ismail.user_sessions(user_id);
CREATE INDEX idx_sessions_token_hash ON ismail.user_sessions(token_hash);
CREATE INDEX idx_sessions_expires_at ON ismail.user_sessions(expires_at);
CREATE INDEX idx_sessions_is_active ON ismail.user_sessions(is_active);

-- Index cartes professionnelles
CREATE INDEX idx_cards_user_id ON ismail.professional_cards(user_id);
CREATE INDEX idx_cards_number ON ismail.professional_cards(card_number);
CREATE INDEX idx_cards_active ON ismail.professional_cards(is_active);

-- Index audit logs
CREATE INDEX idx_audit_user_id ON ismail.audit_logs(user_id);
CREATE INDEX idx_audit_action ON ismail.audit_logs(action);
CREATE INDEX idx_audit_entity ON ismail.audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_created_at ON ismail.audit_logs(created_at);

-- =====================================================
-- COMMENTAIRES
-- =====================================================

-- Tables
COMMENT ON TABLE ismail.users IS 'Utilisateurs de la plateforme ISMAIL';
COMMENT ON TABLE ismail.wallets IS 'Portefeuilles électroniques multi-devises';
COMMENT ON TABLE ismail.transactions IS 'Historique des transactions financières';
COMMENT ON TABLE ismail.user_sessions IS 'Sessions utilisateur actives';
COMMENT ON TABLE ismail.professional_cards IS 'Cartes professionnelles numériques';
COMMENT ON TABLE ismail.audit_logs IS 'Logs d''audit pour conformité RGPD';

-- Colonnes importantes
COMMENT ON COLUMN ismail.users.ismail_id IS 'Identifiant unique ISMAIL (format: CCYYMMDD-XXXX-UL)';
COMMENT ON COLUMN ismail.users.biometric_data IS 'Données biométriques chiffrées (JSON)';
COMMENT ON COLUMN ismail.transactions.reference IS 'Référence unique de transaction';
COMMENT ON COLUMN ismail.transactions.balance_before IS 'Solde avant transaction';
COMMENT ON COLUMN ismail.transactions.balance_after IS 'Solde après transaction';
