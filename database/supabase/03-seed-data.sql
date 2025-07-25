-- ISMAIL Platform - Données de test pour Supabase
-- Données initiales pour développement et tests

-- =====================================================
-- NETTOYAGE DES DONNÉES EXISTANTES
-- =====================================================

-- Désactiver temporairement les triggers d'audit pour éviter les erreurs de FK
ALTER TABLE ismail.users DISABLE TRIGGER IF EXISTS trigger_audit_users;
ALTER TABLE ismail.transactions DISABLE TRIGGER IF EXISTS trigger_audit_transactions;

-- Supprimer les données existantes en respectant les contraintes FK
-- Utiliser TRUNCATE CASCADE pour nettoyer proprement
TRUNCATE TABLE ismail.audit_logs RESTART IDENTITY CASCADE;
TRUNCATE TABLE ismail.transactions RESTART IDENTITY CASCADE;
TRUNCATE TABLE ismail.professional_cards RESTART IDENTITY CASCADE;
TRUNCATE TABLE ismail.user_sessions RESTART IDENTITY CASCADE;
TRUNCATE TABLE ismail.wallets RESTART IDENTITY CASCADE;
TRUNCATE TABLE ismail.users RESTART IDENTITY CASCADE;

-- Réactiver les triggers d'audit
ALTER TABLE ismail.users ENABLE TRIGGER IF EXISTS trigger_audit_users;
ALTER TABLE ismail.transactions ENABLE TRIGGER IF EXISTS trigger_audit_transactions;

-- =====================================================
-- UTILISATEURS DE TEST
-- =====================================================

-- Admin principal
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

-- Commercial test
INSERT INTO ismail.users (
    ismail_id, email, phone, first_name, last_name, 
    profile_type, country, status, kyc_status,
    password_hash, currency, language
) VALUES (
    'CI20241201-COM1-CM',
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

-- Partenaire test (Côte d'Ivoire)
INSERT INTO ismail.users (
    ismail_id, email, phone, first_name, last_name, 
    profile_type, country, status, kyc_status,
    password_hash, currency, language,
    address_line1, city, state_region
) VALUES (
    'CI20241201-PART-PT',
    'partner.ci@ismail-platform.com',
    '+2250123456791',
    'Aminata',
    'Traoré',
    'PARTNER',
    'CI',
    'ACTIVE',
    'APPROVED',
    crypt('PartnerPass123!', gen_salt('bf')),
    'XOF',
    'fr',
    'Rue des Jardins, Cocody',
    'Abidjan',
    'Lagunes'
);

-- Partenaire test (Sénégal)
INSERT INTO ismail.users (
    ismail_id, email, phone, first_name, last_name, 
    profile_type, country, status, kyc_status,
    password_hash, currency, language,
    address_line1, city, state_region
) VALUES (
    'SN20241201-PART-PT',
    'partner.sn@ismail-platform.com',
    '+2217012345678',
    'Fatou',
    'Diop',
    'PARTNER',
    'SN',
    'ACTIVE',
    'APPROVED',
    crypt('PartnerPass123!', gen_salt('bf')),
    'XOF',
    'fr',
    'Avenue Bourguiba, Plateau',
    'Dakar',
    'Dakar'
);

-- Client test (Côte d'Ivoire)
INSERT INTO ismail.users (
    ismail_id, email, phone, first_name, last_name, 
    profile_type, country, status, kyc_status,
    password_hash, currency, language,
    date_of_birth, gender
) VALUES (
    'CI20241201-CLI1-CL',
    'client.ci@ismail-platform.com',
    '+2250123456792',
    'Koffi',
    'Kouassi',
    'CLIENT',
    'CI',
    'ACTIVE',
    'APPROVED',
    crypt('ClientPass123!', gen_salt('bf')),
    'XOF',
    'fr',
    '1990-05-15',
    'M'
);

-- Client test (Ghana)
INSERT INTO ismail.users (
    ismail_id, email, phone, first_name, last_name, 
    profile_type, country, status, kyc_status,
    password_hash, currency, language,
    date_of_birth, gender
) VALUES (
    'GH20241201-CLI1-CL',
    'client.gh@ismail-platform.com',
    '+233201234567',
    'Akosua',
    'Mensah',
    'CLIENT',
    'GH',
    'ACTIVE',
    'APPROVED',
    crypt('ClientPass123!', gen_salt('bf')),
    'GHS',
    'en',
    '1992-08-22',
    'F'
);

-- Client test (Nigeria)
INSERT INTO ismail.users (
    ismail_id, email, phone, first_name, last_name, 
    profile_type, country, status, kyc_status,
    password_hash, currency, language,
    date_of_birth, gender
) VALUES (
    'NG20241201-CLI1-CL',
    'client.ng@ismail-platform.com',
    '+234801234567',
    'Chinedu',
    'Okafor',
    'CLIENT',
    'NG',
    'ACTIVE',
    'APPROVED',
    crypt('ClientPass123!', gen_salt('bf')),
    'NGN',
    'en',
    '1988-12-10',
    'M'
);

-- =====================================================
-- PORTEFEUILLES DE TEST
-- =====================================================

-- Portefeuilles créés automatiquement par trigger
-- Ajoutons des soldes de test

-- Solde pour le partenaire CI
UPDATE ismail.wallets 
SET balance = 1500000.00, daily_limit = 2000000.00, monthly_limit = 10000000.00
WHERE user_id = (SELECT id FROM ismail.users WHERE email = 'partner.ci@ismail-platform.com');

-- Solde pour le partenaire SN
UPDATE ismail.wallets 
SET balance = 800000.00, daily_limit = 1500000.00, monthly_limit = 8000000.00
WHERE user_id = (SELECT id FROM ismail.users WHERE email = 'partner.sn@ismail-platform.com');

-- Solde pour le client CI
UPDATE ismail.wallets 
SET balance = 250000.00, daily_limit = 500000.00, monthly_limit = 2000000.00
WHERE user_id = (SELECT id FROM ismail.users WHERE email = 'client.ci@ismail-platform.com');

-- Portefeuille GHS pour le client Ghana
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM ismail.wallets w
        JOIN ismail.users u ON w.user_id = u.id
        WHERE u.email = 'client.gh@ismail-platform.com' AND w.currency = 'GHS'
    ) THEN
        INSERT INTO ismail.wallets (user_id, currency, balance, daily_limit, monthly_limit)
        SELECT id, 'GHS', 500.00, 2000.00, 10000.00
        FROM ismail.users WHERE email = 'client.gh@ismail-platform.com';
    END IF;
END $$;

-- Portefeuille NGN pour le client Nigeria
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM ismail.wallets w
        JOIN ismail.users u ON w.user_id = u.id
        WHERE u.email = 'client.ng@ismail-platform.com' AND w.currency = 'NGN'
    ) THEN
        INSERT INTO ismail.wallets (user_id, currency, balance, daily_limit, monthly_limit)
        SELECT id, 'NGN', 150000.00, 500000.00, 2000000.00
        FROM ismail.users WHERE email = 'client.ng@ismail-platform.com';
    END IF;
END $$;

-- =====================================================
-- TRANSACTIONS DE TEST
-- =====================================================

-- Transaction de dépôt pour le client CI
INSERT INTO ismail.transactions (
    wallet_id, type, amount, currency, status, reference,
    description, payment_method, payment_provider,
    balance_before, balance_after, completed_at
)
SELECT 
    w.id,
    'DEPOSIT',
    100000.00,
    'XOF',
    'COMPLETED',
    'DEP20241201120000ABC123',
    'Dépôt initial via Orange Money',
    'ORANGE_MONEY',
    'Orange Money CI',
    150000.00,
    250000.00,
    NOW() - INTERVAL '2 days'
FROM ismail.wallets w
JOIN ismail.users u ON w.user_id = u.id
WHERE u.email = 'client.ci@ismail-platform.com' AND w.currency = 'XOF';

-- Transaction de paiement pour le client CI
INSERT INTO ismail.transactions (
    wallet_id, type, amount, currency, status, reference,
    description, payment_method, fee_amount,
    balance_before, balance_after, completed_at
)
SELECT 
    w.id,
    'PAYMENT',
    50000.00,
    'XOF',
    'COMPLETED',
    'PAY20241201140000DEF456',
    'Paiement service de nettoyage',
    'ORANGE_MONEY',
    1000.00,
    250000.00,
    199000.00,
    NOW() - INTERVAL '1 day'
FROM ismail.wallets w
JOIN ismail.users u ON w.user_id = u.id
WHERE u.email = 'client.ci@ismail-platform.com' AND w.currency = 'XOF';

-- Transaction de commission pour le commercial
INSERT INTO ismail.transactions (
    wallet_id, type, amount, currency, status, reference,
    description, payment_method,
    balance_before, balance_after, completed_at
)
SELECT 
    w.id,
    'COMMISSION',
    2000.00,
    'XOF',
    'COMPLETED',
    'COM20241201140500GHI789',
    'Commission sur paiement client CI',
    'ORANGE_MONEY',
    48000.00,
    50000.00,
    NOW() - INTERVAL '1 day'
FROM ismail.wallets w
JOIN ismail.users u ON w.user_id = u.id
WHERE u.email = 'commercial@ismail-platform.com' AND w.currency = 'XOF';

-- =====================================================
-- CARTES PROFESSIONNELLES
-- =====================================================

-- Carte pour le partenaire CI
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM ismail.professional_cards pc
        JOIN ismail.users u ON pc.user_id = u.id
        WHERE u.email = 'partner.ci@ismail-platform.com'
    ) THEN
        INSERT INTO ismail.professional_cards (
            user_id, card_number, qr_code_data, expires_at
        )
        SELECT
            id,
            'ISMAIL-CARD-' || SUBSTRING(ismail_id FROM 1 FOR 8),
            '{"type":"professional_card","ismail_id":"' || ismail_id || '","issued_at":"' || NOW()::text || '"}',
            NOW() + INTERVAL '1 year'
        FROM ismail.users
        WHERE email = 'partner.ci@ismail-platform.com';
    END IF;
END $$;

-- Carte pour le partenaire SN
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM ismail.professional_cards pc
        JOIN ismail.users u ON pc.user_id = u.id
        WHERE u.email = 'partner.sn@ismail-platform.com'
    ) THEN
        INSERT INTO ismail.professional_cards (
            user_id, card_number, qr_code_data, expires_at
        )
        SELECT
            id,
            'ISMAIL-CARD-' || SUBSTRING(ismail_id FROM 1 FOR 8),
            '{"type":"professional_card","ismail_id":"' || ismail_id || '","issued_at":"' || NOW()::text || '"}',
            NOW() + INTERVAL '1 year'
        FROM ismail.users
        WHERE email = 'partner.sn@ismail-platform.com';
    END IF;
END $$;

-- =====================================================
-- SESSIONS DE TEST
-- =====================================================

-- Session active pour le client CI
INSERT INTO ismail.user_sessions (
    user_id, token_hash, refresh_token_hash, 
    device_info, ip_address, user_agent,
    expires_at, last_activity_at
)
SELECT 
    id,
    encode(digest('test_token_' || id::text, 'sha256'), 'hex'),
    encode(digest('test_refresh_' || id::text, 'sha256'), 'hex'),
    '{"device":"iPhone 13","os":"iOS 16.1","app_version":"1.0.0"}',
    '192.168.1.100'::inet,
    'ISMAIL-Mobile/1.0.0 (iOS 16.1)',
    NOW() + INTERVAL '7 days',
    NOW()
FROM ismail.users 
WHERE email = 'client.ci@ismail-platform.com';

-- =====================================================
-- DONNÉES DE CONFIGURATION
-- =====================================================

-- Table de configuration (optionnelle)
CREATE TABLE IF NOT EXISTS ismail.app_config (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Configuration des taux de change
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ismail.app_config WHERE key = 'exchange_rates') THEN
        INSERT INTO ismail.app_config (key, value, description) VALUES
        ('exchange_rates', '{
            "XOF": {"EUR": 0.00152, "USD": 0.00164, "GHS": 0.0196, "NGN": 0.756},
            "GHS": {"XOF": 51.02, "EUR": 0.0775, "USD": 0.0837, "NGN": 38.57},
            "NGN": {"XOF": 1.323, "EUR": 0.00201, "USD": 0.00217, "GHS": 0.0259},
            "EUR": {"XOF": 658.5, "GHS": 12.9, "NGN": 497.8, "USD": 1.08},
            "USD": {"XOF": 609.7, "GHS": 11.95, "NGN": 460.5, "EUR": 0.926}
        }', 'Taux de change entre devises');
    END IF;
END $$;

-- Configuration des frais de transaction
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ismail.app_config WHERE key = 'transaction_fees') THEN
        INSERT INTO ismail.app_config (key, value, description) VALUES
        ('transaction_fees', '{
            "DEPOSIT": {"percentage": 0, "fixed": 0, "min": 0, "max": 0},
            "WITHDRAWAL": {"percentage": 1.5, "fixed": 500, "min": 500, "max": 5000},
            "TRANSFER": {"percentage": 0.5, "fixed": 200, "min": 200, "max": 2000},
            "PAYMENT": {"percentage": 2, "fixed": 1000, "min": 1000, "max": 10000}
        }', 'Frais de transaction par type');
    END IF;
END $$;

-- Configuration des limites par pays
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ismail.app_config WHERE key = 'country_limits') THEN
        INSERT INTO ismail.app_config (key, value, description) VALUES
        ('country_limits', '{
            "CI": {"daily": 500000, "monthly": 2000000, "currency": "XOF"},
            "SN": {"daily": 500000, "monthly": 2000000, "currency": "XOF"},
            "BF": {"daily": 500000, "monthly": 2000000, "currency": "XOF"},
            "ML": {"daily": 500000, "monthly": 2000000, "currency": "XOF"},
            "GH": {"daily": 2000, "monthly": 10000, "currency": "GHS"},
            "NG": {"daily": 500000, "monthly": 2000000, "currency": "NGN"}
        }', 'Limites de transaction par pays');
    END IF;
END $$;

-- Configuration des moyens de paiement par pays
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ismail.app_config WHERE key = 'payment_methods') THEN
        INSERT INTO ismail.app_config (key, value, description) VALUES
        ('payment_methods', '{
            "CI": ["ORANGE_MONEY", "MTN_MOMO", "WAVE", "CINETPAY"],
            "SN": ["ORANGE_MONEY", "WAVE", "CINETPAY"],
            "BF": ["ORANGE_MONEY", "CINETPAY"],
            "ML": ["ORANGE_MONEY", "CINETPAY"],
            "GH": ["MTN_MOMO", "CINETPAY"],
            "NG": ["CINETPAY"],
            "TG": ["CINETPAY"],
            "BJ": ["CINETPAY"]
        }', 'Moyens de paiement disponibles par pays');
    END IF;
END $$;

-- =====================================================
-- STATISTIQUES INITIALES
-- =====================================================

-- Créer quelques logs d'audit pour les tests
INSERT INTO ismail.audit_logs (user_id, action, entity_type, entity_id, new_values)
SELECT
    u.id,
    'CREATE',
    'users',
    u.id,
    row_to_json(u.*)
FROM ismail.users u;

-- =====================================================
-- FONCTIONS DE NETTOYAGE POUR LES TESTS
-- =====================================================

-- Fonction pour réinitialiser les données de test
CREATE OR REPLACE FUNCTION ismail.reset_test_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Supprimer les données de test (sauf admin)
    DELETE FROM ismail.user_sessions WHERE user_id != (
        SELECT id FROM ismail.users WHERE email = 'admin@ismail-platform.com'
    );
    
    DELETE FROM ismail.professional_cards WHERE user_id != (
        SELECT id FROM ismail.users WHERE email = 'admin@ismail-platform.com'
    );
    
    DELETE FROM ismail.transactions WHERE wallet_id IN (
        SELECT w.id FROM ismail.wallets w
        JOIN ismail.users u ON w.user_id = u.id
        WHERE u.email != 'admin@ismail-platform.com'
    );
    
    DELETE FROM ismail.wallets WHERE user_id != (
        SELECT id FROM ismail.users WHERE email = 'admin@ismail-platform.com'
    );
    
    DELETE FROM ismail.users WHERE email != 'admin@ismail-platform.com';
    
    -- Réinitialiser les séquences si nécessaire
    -- (PostgreSQL gère automatiquement les UUID)
    
    RAISE NOTICE 'Données de test réinitialisées avec succès';
END;
$$;

-- =====================================================
-- COMMENTAIRES
-- =====================================================

COMMENT ON TABLE ismail.app_config IS 'Configuration globale de l''application';
COMMENT ON FUNCTION ismail.reset_test_data() IS 'Réinitialise les données de test (garde seulement l''admin)';

-- Afficher un résumé des données créées
DO $$
DECLARE
    user_count INTEGER;
    wallet_count INTEGER;
    transaction_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM ismail.users;
    SELECT COUNT(*) INTO wallet_count FROM ismail.wallets;
    SELECT COUNT(*) INTO transaction_count FROM ismail.transactions;
    
    RAISE NOTICE '=== DONNÉES DE TEST CRÉÉES ===';
    RAISE NOTICE 'Utilisateurs: %', user_count;
    RAISE NOTICE 'Portefeuilles: %', wallet_count;
    RAISE NOTICE 'Transactions: %', transaction_count;
    RAISE NOTICE '================================';
END $$;
