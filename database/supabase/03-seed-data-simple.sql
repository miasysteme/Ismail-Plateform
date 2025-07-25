-- ISMAIL Platform - Données de test simplifiées pour Supabase
-- Version simplifiée sans nettoyage pour éviter les conflits

-- =====================================================
-- UTILISATEURS DE TEST (avec vérification d'existence)
-- =====================================================

-- Admin principal
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ismail.users WHERE email = 'admin@ismail-platform.com') THEN
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
END $$;

-- Commercial test
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ismail.users WHERE email = 'commercial@ismail-platform.com') THEN
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
    END IF;
END $$;

-- Partenaire test (Côte d'Ivoire)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ismail.users WHERE email = 'partner.ci@ismail-platform.com') THEN
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
            '123 Rue des Partenaires',
            'Abidjan',
            'Lagunes'
        );
    END IF;
END $$;

-- Client test (Côte d'Ivoire)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ismail.users WHERE email = 'client.ci@ismail-platform.com') THEN
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
            'Client',
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
    END IF;
END $$;

-- =====================================================
-- CONFIGURATION SYSTÈME BASIQUE
-- =====================================================

-- Créer la table app_config si elle n'existe pas
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
            "XOF": {"EUR": 0.00152, "USD": 0.00164},
            "EUR": {"XOF": 658.5, "USD": 1.08},
            "USD": {"XOF": 609.7, "EUR": 0.926}
        }', 'Taux de change entre devises');
    END IF;
END $$;

-- =====================================================
-- RÉSUMÉ DES DONNÉES CRÉÉES
-- =====================================================

-- Afficher un résumé
DO $$
DECLARE
    user_count INTEGER;
    config_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM ismail.users;
    SELECT COUNT(*) INTO config_count FROM ismail.app_config;
    
    RAISE NOTICE '=== RÉSUMÉ DES DONNÉES DE TEST ===';
    RAISE NOTICE 'Utilisateurs créés: %', user_count;
    RAISE NOTICE 'Configurations créées: %', config_count;
    RAISE NOTICE '================================';
    RAISE NOTICE 'Comptes de test disponibles:';
    RAISE NOTICE '- Admin: admin@ismail-platform.com (mot de passe: AdminPassword123!)';
    RAISE NOTICE '- Commercial: commercial@ismail-platform.com (mot de passe: CommercialPass123!)';
    RAISE NOTICE '- Partenaire: partner.ci@ismail-platform.com (mot de passe: PartnerPass123!)';
    RAISE NOTICE '- Client: client.ci@ismail-platform.com (mot de passe: ClientPass123!)';
    RAISE NOTICE '================================';
END $$;
