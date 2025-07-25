-- ISMAIL Platform - Configuration complète pour Supabase
-- Script unique qui crée tout : schéma, tables, fonctions et données de test

-- =====================================================
-- CRÉATION DU SCHÉMA ET EXTENSIONS
-- =====================================================

-- Créer le schéma ismail s'il n'existe pas
CREATE SCHEMA IF NOT EXISTS ismail;

-- Activer les extensions nécessaires
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- TYPES ÉNUMÉRÉS
-- =====================================================

-- Type pour le profil utilisateur
DO $$ BEGIN
    CREATE TYPE ismail.profile_type AS ENUM ('CLIENT', 'PARTNER', 'COMMERCIAL', 'ADMIN');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Type pour le statut utilisateur
DO $$ BEGIN
    CREATE TYPE ismail.user_status AS ENUM ('ACTIVE', 'INACTIVE', 'SUSPENDED', 'PENDING');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Type pour le statut KYC
DO $$ BEGIN
    CREATE TYPE ismail.kyc_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'EXPIRED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Type pour le statut de transaction
DO $$ BEGIN
    CREATE TYPE ismail.transaction_status AS ENUM ('PENDING', 'COMPLETED', 'FAILED', 'CANCELLED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Type pour le type de transaction
DO $$ BEGIN
    CREATE TYPE ismail.transaction_type AS ENUM ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER', 'PAYMENT', 'COMMISSION', 'REFUND');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- =====================================================
-- TABLE UTILISATEURS
-- =====================================================

CREATE TABLE IF NOT EXISTS ismail.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Identifiant unique ISMAIL
    ismail_id VARCHAR(20) UNIQUE NOT NULL,
    
    -- Informations de base
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    
    -- Informations personnelles
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    gender CHAR(1) CHECK (gender IN ('M', 'F')),
    
    -- Adresse
    address_line1 TEXT,
    address_line2 TEXT,
    city VARCHAR(100),
    state_region VARCHAR(100),
    postal_code VARCHAR(20),
    country CHAR(2) NOT NULL, -- Code ISO 3166-1 alpha-2
    
    -- Profil et statut
    profile_type ismail.profile_type NOT NULL DEFAULT 'CLIENT',
    status ismail.user_status NOT NULL DEFAULT 'PENDING',
    kyc_status ismail.kyc_status NOT NULL DEFAULT 'PENDING',
    
    -- Préférences
    currency CHAR(3) NOT NULL DEFAULT 'XOF', -- Code ISO 4217
    language CHAR(2) NOT NULL DEFAULT 'fr', -- Code ISO 639-1
    timezone VARCHAR(50) DEFAULT 'Africa/Abidjan',
    
    -- Métadonnées
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE,
    email_verified_at TIMESTAMP WITH TIME ZONE,
    phone_verified_at TIMESTAMP WITH TIME ZONE
);

-- =====================================================
-- TABLE PORTEFEUILLES
-- =====================================================

CREATE TABLE IF NOT EXISTS ismail.wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Référence utilisateur
    user_id UUID NOT NULL REFERENCES ismail.users(id) ON DELETE CASCADE,
    
    -- Devise et solde
    currency CHAR(3) NOT NULL, -- Code ISO 4217
    balance DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    
    -- Limites
    daily_limit DECIMAL(15,2) DEFAULT 100000.00,
    monthly_limit DECIMAL(15,2) DEFAULT 500000.00,
    
    -- Statut
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_frozen BOOLEAN NOT NULL DEFAULT false,
    
    -- Métadonnées
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Contrainte d'unicité : un portefeuille par devise par utilisateur
    UNIQUE(user_id, currency)
);

-- =====================================================
-- TABLE TRANSACTIONS
-- =====================================================

CREATE TABLE IF NOT EXISTS ismail.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Référence portefeuille
    wallet_id UUID NOT NULL REFERENCES ismail.wallets(id) ON DELETE RESTRICT,
    
    -- Détails de la transaction
    type ismail.transaction_type NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    currency CHAR(3) NOT NULL,
    
    -- Statut et référence
    status ismail.transaction_status NOT NULL DEFAULT 'PENDING',
    reference VARCHAR(100) UNIQUE NOT NULL,
    
    -- Description et métadonnées
    description TEXT,
    payment_method VARCHAR(50),
    payment_provider VARCHAR(50),
    
    -- Frais
    fee_amount DECIMAL(15,2) DEFAULT 0.00,
    
    -- Soldes avant/après
    balance_before DECIMAL(15,2),
    balance_after DECIMAL(15,2),
    
    -- Horodatage
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- =====================================================
-- FONCTIONS UTILITAIRES
-- =====================================================

-- Fonction pour générer un ID ISMAIL unique
CREATE OR REPLACE FUNCTION ismail.generate_ismail_id(
    p_country_code CHAR(2),
    p_profile_type ismail.profile_type DEFAULT 'CLIENT'
)
RETURNS VARCHAR(20)
LANGUAGE plpgsql
AS $$
DECLARE
    v_date_part VARCHAR(8);
    v_random_part VARCHAR(4);
    v_suffix VARCHAR(2);
    v_ismail_id VARCHAR(20);
    v_exists BOOLEAN;
BEGIN
    -- Partie date (YYYYMMDD)
    v_date_part := TO_CHAR(NOW(), 'YYYYMMDD');
    
    -- Suffixe selon le type de profil
    v_suffix := CASE p_profile_type
        WHEN 'CLIENT' THEN 'CL'
        WHEN 'PARTNER' THEN 'PT'
        WHEN 'COMMERCIAL' THEN 'CM'
        WHEN 'ADMIN' THEN 'AD'
        ELSE 'CL'
    END;
    
    -- Générer un ID unique
    LOOP
        -- Partie aléatoire (4 caractères)
        v_random_part := UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 4));
        
        -- Construire l'ID complet
        v_ismail_id := p_country_code || v_date_part || '-' || v_random_part || '-' || v_suffix;
        
        -- Vérifier l'unicité
        SELECT EXISTS(
            SELECT 1 FROM ismail.users WHERE ismail_id = v_ismail_id
        ) INTO v_exists;
        
        EXIT WHEN NOT v_exists;
    END LOOP;
    
    RETURN v_ismail_id;
END;
$$;

-- Fonction pour créer un portefeuille par défaut
CREATE OR REPLACE FUNCTION ismail.create_default_wallet()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Créer un portefeuille par défaut dans la devise de l'utilisateur
    INSERT INTO ismail.wallets (user_id, currency, balance, daily_limit, monthly_limit)
    VALUES (
        NEW.id,
        NEW.currency,
        0.00,
        CASE NEW.country
            WHEN 'CI' THEN 500000.00  -- 500,000 XOF
            WHEN 'SN' THEN 500000.00  -- 500,000 XOF
            WHEN 'GH' THEN 2000.00    -- 2,000 GHS
            WHEN 'NG' THEN 500000.00  -- 500,000 NGN
            ELSE 100000.00
        END,
        CASE NEW.country
            WHEN 'CI' THEN 2000000.00  -- 2,000,000 XOF
            WHEN 'SN' THEN 2000000.00  -- 2,000,000 XOF
            WHEN 'GH' THEN 10000.00    -- 10,000 GHS
            WHEN 'NG' THEN 2000000.00  -- 2,000,000 NGN
            ELSE 500000.00
        END
    );
    
    RETURN NEW;
END;
$$;

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger pour créer un portefeuille par défaut
DROP TRIGGER IF EXISTS trigger_create_default_wallet ON ismail.users;
CREATE TRIGGER trigger_create_default_wallet
    AFTER INSERT ON ismail.users
    FOR EACH ROW
    EXECUTE FUNCTION ismail.create_default_wallet();

-- =====================================================
-- DONNÉES DE TEST
-- =====================================================

-- Créer les utilisateurs de test avec gestion complète des conflits
DO $$
BEGIN
    -- Admin principal
    IF NOT EXISTS (
        SELECT 1 FROM ismail.users
        WHERE email = 'admin@ismail-platform.com'
           OR phone = '+2250123456789'
           OR ismail_id = 'CI20241201-ADMIN-AD'
    ) THEN
        INSERT INTO ismail.users (
            ismail_id, email, phone, first_name, last_name,
            profile_type, country, status, kyc_status,
            password_hash, currency, language
        ) VALUES (
            'CI20241201-ADMIN-AD',
            'admin@ismail-platform.com',
            '+2250123456789',
            'Admin',
            'ISMAIL',
            'ADMIN',
            'CI',
            'ACTIVE',
            'APPROVED',
            crypt('AdminPassword123!', gen_salt('bf')),
            'XOF',
            'fr'
        );
    END IF;

    -- Commercial test
    IF NOT EXISTS (
        SELECT 1 FROM ismail.users
        WHERE email = 'commercial@ismail-platform.com'
           OR phone = '+2250123456790'
           OR ismail_id = 'CI20241201-COM01-CM'
    ) THEN
        INSERT INTO ismail.users (
            ismail_id, email, phone, first_name, last_name,
            profile_type, country, status, kyc_status,
            password_hash, currency, language
        ) VALUES (
            'CI20241201-COM01-CM',
            'commercial@ismail-platform.com',
            '+2250123456790',
            'Kouadio',
            'Commercial',
            'COMMERCIAL',
            'CI',
            'ACTIVE',
            'APPROVED',
            crypt('CommercialPass123!', gen_salt('bf')),
            'XOF',
            'fr'
        );
    END IF;

    -- Partenaire test
    IF NOT EXISTS (
        SELECT 1 FROM ismail.users
        WHERE email = 'partner@ismail-platform.com'
           OR phone = '+2250123456791'
           OR ismail_id = 'CI20241201-PART1-PT'
    ) THEN
        INSERT INTO ismail.users (
            ismail_id, email, phone, first_name, last_name,
            profile_type, country, status, kyc_status,
            password_hash, currency, language
        ) VALUES (
            'CI20241201-PART1-PT',
            'partner@ismail-platform.com',
            '+2250123456791',
            'Aminata',
            'Traoré',
            'PARTNER',
            'CI',
            'ACTIVE',
            'APPROVED',
            crypt('PartnerPass123!', gen_salt('bf')),
            'XOF',
            'fr'
        );
    END IF;

    -- Client test
    IF NOT EXISTS (
        SELECT 1 FROM ismail.users
        WHERE email = 'client@ismail-platform.com'
           OR phone = '+2250123456792'
           OR ismail_id = 'CI20241201-CLI01-CL'
    ) THEN
        INSERT INTO ismail.users (
            ismail_id, email, phone, first_name, last_name,
            profile_type, country, status, kyc_status,
            password_hash, currency, language
        ) VALUES (
            'CI20241201-CLI01-CL',
            'client@ismail-platform.com',
            '+2250123456792',
            'Koffi',
            'Kouassi',
            'CLIENT',
            'CI',
            'ACTIVE',
            'APPROVED',
            crypt('ClientPass123!', gen_salt('bf')),
            'XOF',
            'fr'
        );
    END IF;
END $$;

-- Afficher un résumé
DO $$
DECLARE
    user_count INTEGER;
    wallet_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM ismail.users;
    SELECT COUNT(*) INTO wallet_count FROM ismail.wallets;
    
    RAISE NOTICE '=== ISMAIL PLATFORM - BASE DE DONNÉES CRÉÉE ===';
    RAISE NOTICE 'Utilisateurs créés: %', user_count;
    RAISE NOTICE 'Portefeuilles créés: %', wallet_count;
    RAISE NOTICE '===============================================';
    RAISE NOTICE 'Comptes de test disponibles:';
    RAISE NOTICE '- Admin: admin@ismail-platform.com (AdminPassword123!)';
    RAISE NOTICE '- Commercial: commercial@ismail-platform.com (CommercialPass123!)';
    RAISE NOTICE '- Partenaire: partner@ismail-platform.com (PartnerPass123!)';
    RAISE NOTICE '- Client: client@ismail-platform.com (ClientPass123!)';
    RAISE NOTICE '===============================================';
END $$;
