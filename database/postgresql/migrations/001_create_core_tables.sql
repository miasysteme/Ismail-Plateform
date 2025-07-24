-- Migration 001: Création des tables core - Plateforme ISMAIL
-- Tables pour l'authentification, utilisateurs et portefeuille

-- =====================================================
-- TABLES UTILISATEURS ET AUTHENTIFICATION
-- =====================================================

-- Table utilisateurs principale
CREATE TABLE core.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ismail_id VARCHAR(16) UNIQUE NOT NULL DEFAULT core.generate_ismail_id(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    gender VARCHAR(10) CHECK (gender IN ('MALE', 'FEMALE', 'OTHER')),
    profile_type VARCHAR(20) NOT NULL CHECK (profile_type IN ('CLIENT', 'PARTNER', 'COMMERCIAL', 'ADMIN')),
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'ACTIVE', 'SUSPENDED', 'BLOCKED')),
    kyc_status VARCHAR(20) DEFAULT 'PENDING' CHECK (kyc_status IN ('PENDING', 'VERIFIED', 'REJECTED')),
    kyc_verified_at TIMESTAMP,
    last_login_at TIMESTAMP,
    login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP,
    password_changed_at TIMESTAMP DEFAULT NOW(),
    terms_accepted_at TIMESTAMP,
    privacy_accepted_at TIMESTAMP,
    marketing_consent BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Index pour performance
CREATE INDEX idx_users_ismail_id ON core.users(ismail_id);
CREATE INDEX idx_users_email ON core.users(email);
CREATE INDEX idx_users_phone ON core.users(phone);
CREATE INDEX idx_users_status ON core.users(status);
CREATE INDEX idx_users_profile_type ON core.users(profile_type);
CREATE INDEX idx_users_kyc_status ON core.users(kyc_status);
CREATE INDEX idx_users_created_at ON core.users(created_at);

-- Trigger pour mise à jour automatique
CREATE TRIGGER users_updated_at_trigger
    BEFORE UPDATE ON core.users
    FOR EACH ROW
    EXECUTE FUNCTION core.update_updated_at_column();

-- Trigger d'audit
CREATE TRIGGER users_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON core.users
    FOR EACH ROW
    EXECUTE FUNCTION audit.audit_trigger_function();

-- Table données biométriques (chiffrées)
CREATE TABLE core.user_biometrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES core.users(id) ON DELETE CASCADE,
    fingerprint_hash VARCHAR(512) NOT NULL,
    face_encoding TEXT NOT NULL,
    biometric_template BYTEA, -- Template chiffré
    verification_score DECIMAL(5,4) CHECK (verification_score >= 0 AND verification_score <= 1),
    algorithm_version VARCHAR(20) DEFAULT '1.0',
    device_info JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL DEFAULT (NOW() + INTERVAL '1 year'),
    
    CONSTRAINT unique_user_biometric UNIQUE (user_id)
);

-- Index pour performance
CREATE INDEX idx_biometrics_user_id ON core.user_biometrics(user_id);
CREATE INDEX idx_biometrics_expires_at ON core.user_biometrics(expires_at);

-- Table cartes d'identité professionnelles
CREATE TABLE core.professional_cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES core.users(id) ON DELETE CASCADE,
    card_number VARCHAR(16) UNIQUE NOT NULL,
    qr_code_data TEXT NOT NULL,
    qr_code_secret VARCHAR(255) NOT NULL, -- Secret pour validation
    photo_url VARCHAR(500),
    template_version VARCHAR(10) DEFAULT '1.0',
    issued_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL DEFAULT (NOW() + INTERVAL '1 year'),
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'EXPIRED', 'REVOKED', 'SUSPENDED')),
    revocation_reason TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT unique_user_card UNIQUE (user_id, status) DEFERRABLE
);

-- Index pour performance
CREATE INDEX idx_cards_user_id ON core.professional_cards(user_id);
CREATE INDEX idx_cards_card_number ON core.professional_cards(card_number);
CREATE INDEX idx_cards_status ON core.professional_cards(status);
CREATE INDEX idx_cards_expires_at ON core.professional_cards(expires_at);

-- Table sessions utilisateur
CREATE TABLE core.user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES core.users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    refresh_token VARCHAR(255) UNIQUE NOT NULL,
    device_id VARCHAR(255),
    device_type VARCHAR(50),
    device_name VARCHAR(255),
    ip_address INET,
    user_agent TEXT,
    location JSONB, -- Géolocalisation approximative
    is_active BOOLEAN DEFAULT true,
    last_activity_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Index pour performance
CREATE INDEX idx_sessions_user_id ON core.user_sessions(user_id);
CREATE INDEX idx_sessions_token ON core.user_sessions(session_token);
CREATE INDEX idx_sessions_refresh_token ON core.user_sessions(refresh_token);
CREATE INDEX idx_sessions_expires_at ON core.user_sessions(expires_at);
CREATE INDEX idx_sessions_is_active ON core.user_sessions(is_active);

-- =====================================================
-- TABLES PORTEFEUILLE ET TRANSACTIONS
-- =====================================================

-- Table portefeuilles
CREATE TABLE core.wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES core.users(id) ON DELETE CASCADE,
    balance DECIMAL(15,2) DEFAULT 0.00 CHECK (balance >= 0),
    currency VARCHAR(3) DEFAULT 'XOF',
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'FROZEN', 'CLOSED')),
    daily_limit DECIMAL(15,2) DEFAULT 1000000.00,
    monthly_limit DECIMAL(15,2) DEFAULT 10000000.00,
    daily_spent DECIMAL(15,2) DEFAULT 0.00,
    monthly_spent DECIMAL(15,2) DEFAULT 0.00,
    last_reset_daily DATE DEFAULT CURRENT_DATE,
    last_reset_monthly DATE DEFAULT DATE_TRUNC('month', CURRENT_DATE),
    pin_hash VARCHAR(255), -- PIN pour transactions
    pin_attempts INTEGER DEFAULT 0,
    pin_locked_until TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT unique_user_wallet UNIQUE (user_id, currency)
);

-- Index pour performance
CREATE INDEX idx_wallets_user_id ON core.wallets(user_id);
CREATE INDEX idx_wallets_status ON core.wallets(status);
CREATE INDEX idx_wallets_currency ON core.wallets(currency);

-- Trigger pour mise à jour automatique
CREATE TRIGGER wallets_updated_at_trigger
    BEFORE UPDATE ON core.wallets
    FOR EACH ROW
    EXECUTE FUNCTION core.update_updated_at_column();

-- Table transactions avec partitioning par date
CREATE TABLE core.transactions (
    id UUID NOT NULL DEFAULT uuid_generate_v4(),
    wallet_id UUID NOT NULL,
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('CREDIT', 'DEBIT', 'TRANSFER', 'COMMISSION', 'CASHBACK', 'REFUND')),
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    balance_before DECIMAL(15,2) NOT NULL,
    balance_after DECIMAL(15,2) NOT NULL,
    description TEXT,
    reference VARCHAR(100) UNIQUE,
    external_reference VARCHAR(100),
    related_transaction_id UUID, -- Pour les transfers et refunds
    metadata JSONB,
    payment_method VARCHAR(50), -- ORANGE_MONEY, MTN_MONEY, CARD, etc.
    payment_reference VARCHAR(100),
    fees DECIMAL(15,2) DEFAULT 0.00,
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'CANCELLED', 'REVERSED')),
    failure_reason TEXT,
    processed_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    
    PRIMARY KEY (id, created_at),
    
    -- Contrainte de cohérence pour les soldes
    CONSTRAINT check_balance_consistency CHECK (
        (transaction_type IN ('CREDIT', 'COMMISSION', 'CASHBACK', 'REFUND') AND balance_after = balance_before + amount) OR
        (transaction_type IN ('DEBIT', 'TRANSFER') AND balance_after = balance_before - amount)
    )
) PARTITION BY RANGE (created_at);

-- Partitions mensuelles pour les transactions
CREATE TABLE core.transactions_2024_01 PARTITION OF core.transactions
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE core.transactions_2024_02 PARTITION OF core.transactions
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

CREATE TABLE core.transactions_2024_03 PARTITION OF core.transactions
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');

-- Index pour performance sur les partitions
CREATE INDEX idx_transactions_wallet_id ON core.transactions(wallet_id);
CREATE INDEX idx_transactions_type ON core.transactions(transaction_type);
CREATE INDEX idx_transactions_status ON core.transactions(status);
CREATE INDEX idx_transactions_reference ON core.transactions(reference);
CREATE INDEX idx_transactions_payment_method ON core.transactions(payment_method);
CREATE INDEX idx_transactions_created_at ON core.transactions(created_at);

-- Table commissions commerciales
CREATE TABLE core.commissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    commercial_id UUID REFERENCES core.users(id),
    partner_id UUID REFERENCES core.users(id),
    transaction_id UUID, -- Référence vers la transaction source
    commission_type VARCHAR(20) NOT NULL CHECK (commission_type IN ('DIRECT', 'TEAM', 'BONUS')),
    base_amount DECIMAL(15,2) NOT NULL, -- Montant de base pour calcul
    commission_rate DECIMAL(5,4) NOT NULL, -- Taux de commission (ex: 0.04 = 4%)
    commission_amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'XOF',
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'CALCULATED', 'PAID', 'CANCELLED')),
    paid_at TIMESTAMP,
    payment_reference VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT check_commission_amount CHECK (commission_amount = base_amount * commission_rate)
);

-- Index pour performance
CREATE INDEX idx_commissions_commercial_id ON core.commissions(commercial_id);
CREATE INDEX idx_commissions_partner_id ON core.commissions(partner_id);
CREATE INDEX idx_commissions_period ON core.commissions(period_start, period_end);
CREATE INDEX idx_commissions_status ON core.commissions(status);
CREATE INDEX idx_commissions_type ON core.commissions(commission_type);

-- =====================================================
-- TABLES DE CONFIGURATION
-- =====================================================

-- Table paramètres système
CREATE TABLE core.system_parameters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parameter_key VARCHAR(100) UNIQUE NOT NULL,
    parameter_value TEXT NOT NULL,
    parameter_type VARCHAR(20) DEFAULT 'STRING' CHECK (parameter_type IN ('STRING', 'INTEGER', 'DECIMAL', 'BOOLEAN', 'JSON')),
    description TEXT,
    is_encrypted BOOLEAN DEFAULT false,
    is_public BOOLEAN DEFAULT false, -- Visible côté client
    category VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Index pour performance
CREATE INDEX idx_system_parameters_key ON core.system_parameters(parameter_key);
CREATE INDEX idx_system_parameters_category ON core.system_parameters(category);
CREATE INDEX idx_system_parameters_public ON core.system_parameters(is_public);

-- Paramètres par défaut
INSERT INTO core.system_parameters (parameter_key, parameter_value, parameter_type, description, category) VALUES
('CREDIT_TO_FCFA_RATE', '50', 'DECIMAL', 'Taux de conversion 1 crédit = X FCFA', 'WALLET'),
('MIN_CREDIT_PURCHASE', '100', 'INTEGER', 'Achat minimum de crédits', 'WALLET'),
('CREDIT_EXPIRY_MONTHS', '12', 'INTEGER', 'Expiration des crédits en mois', 'WALLET'),
('MAX_DAILY_TRANSACTIONS', '50', 'INTEGER', 'Nombre max de transactions par jour', 'SECURITY'),
('KYC_VALIDITY_MONTHS', '12', 'INTEGER', 'Validité de la vérification KYC en mois', 'SECURITY'),
('COMMISSION_RATE_JUNIOR', '0.04', 'DECIMAL', 'Taux commission commercial junior', 'COMMISSION'),
('COMMISSION_RATE_SENIOR', '0.06', 'DECIMAL', 'Taux commission commercial senior', 'COMMISSION'),
('MIN_RATING_REQUIRED', '4.0', 'DECIMAL', 'Note minimum requise pour les prestataires', 'QUALITY');

-- Table taux de change (pour support multi-devises futur)
CREATE TABLE core.exchange_rates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    from_currency VARCHAR(3) NOT NULL,
    to_currency VARCHAR(3) NOT NULL,
    rate DECIMAL(15,8) NOT NULL,
    source VARCHAR(50), -- API source du taux
    valid_from TIMESTAMP DEFAULT NOW(),
    valid_until TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT unique_currency_pair_date UNIQUE (from_currency, to_currency, valid_from)
);

-- Index pour performance
CREATE INDEX idx_exchange_rates_currencies ON core.exchange_rates(from_currency, to_currency);
CREATE INDEX idx_exchange_rates_valid_from ON core.exchange_rates(valid_from);
CREATE INDEX idx_exchange_rates_active ON core.exchange_rates(is_active);

-- =====================================================
-- FONCTIONS UTILITAIRES
-- =====================================================

-- Fonction pour mise à jour automatique du timestamp
CREATE OR REPLACE FUNCTION core.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour générer une référence de transaction unique
CREATE OR REPLACE FUNCTION core.generate_transaction_reference()
RETURNS VARCHAR(20) AS $$
DECLARE
    prefix VARCHAR(3) := 'TXN';
    timestamp_part VARCHAR(10);
    random_part VARCHAR(7);
    result VARCHAR(20);
BEGIN
    timestamp_part := TO_CHAR(NOW(), 'YYMMDDHHMI');
    random_part := UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 7));
    
    result := prefix || timestamp_part || random_part;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour calculer les commissions
CREATE OR REPLACE FUNCTION core.calculate_commission(
    commercial_user_id UUID,
    base_amount DECIMAL,
    commission_type VARCHAR DEFAULT 'DIRECT'
) RETURNS DECIMAL AS $$
DECLARE
    user_profile_type VARCHAR;
    commission_rate DECIMAL;
    result DECIMAL;
BEGIN
    -- Récupérer le type de profil
    SELECT profile_type INTO user_profile_type
    FROM core.users
    WHERE id = commercial_user_id;
    
    -- Déterminer le taux selon le type
    IF commission_type = 'DIRECT' THEN
        IF user_profile_type = 'COMMERCIAL' THEN
            commission_rate := 0.04; -- 4% pour junior
        ELSE
            commission_rate := 0.06; -- 6% pour senior
        END IF;
    ELSIF commission_type = 'TEAM' THEN
        commission_rate := 0.02; -- 2% pour équipe
    ELSE
        commission_rate := 0.01; -- 1% pour bonus
    END IF;
    
    result := base_amount * commission_rate;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- VUES UTILES
-- =====================================================

-- Vue pour statistiques utilisateurs
CREATE VIEW analytics.user_stats AS
SELECT 
    profile_type,
    status,
    kyc_status,
    COUNT(*) as user_count,
    COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as new_users_30d,
    COUNT(*) FILTER (WHERE last_login_at >= CURRENT_DATE - INTERVAL '7 days') as active_users_7d
FROM core.users
GROUP BY profile_type, status, kyc_status;

-- Vue pour statistiques portefeuille
CREATE VIEW analytics.wallet_stats AS
SELECT 
    currency,
    status,
    COUNT(*) as wallet_count,
    SUM(balance) as total_balance,
    AVG(balance) as avg_balance,
    MIN(balance) as min_balance,
    MAX(balance) as max_balance
FROM core.wallets
GROUP BY currency, status;

-- Vue pour statistiques transactions
CREATE VIEW analytics.transaction_stats AS
SELECT 
    DATE_TRUNC('day', created_at) as transaction_date,
    transaction_type,
    status,
    COUNT(*) as transaction_count,
    SUM(amount) as total_amount,
    AVG(amount) as avg_amount
FROM core.transactions
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', created_at), transaction_type, status
ORDER BY transaction_date DESC;

-- =====================================================
-- FINALISATION
-- =====================================================

-- Mise à jour des statistiques
ANALYZE core.users;
ANALYZE core.wallets;
ANALYZE core.transactions;
ANALYZE core.commissions;

-- Message de confirmation
DO $$
BEGIN
    RAISE NOTICE 'Migration 001 terminée avec succès!';
    RAISE NOTICE 'Tables créées: users, user_biometrics, professional_cards, user_sessions';
    RAISE NOTICE 'Tables créées: wallets, transactions, commissions, system_parameters';
    RAISE NOTICE 'Fonctions créées: generate_ismail_id, calculate_commission, etc.';
    RAISE NOTICE 'Vues analytiques créées: user_stats, wallet_stats, transaction_stats';
END $$;
