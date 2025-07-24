-- Script de données de test - Plateforme ISMAIL
-- Insertion de données de démonstration pour développement et tests

-- =====================================================
-- UTILISATEURS DE TEST
-- =====================================================

-- Insérer des utilisateurs de test avec différents profils
INSERT INTO core.users (
    email, phone, password_hash, first_name, last_name, 
    profile_type, status, kyc_status, kyc_verified_at,
    terms_accepted_at, privacy_accepted_at, marketing_consent
) VALUES
-- Administrateurs
('admin@ismail-platform.com', '+2250701234567', '$2a$12$LQv3c1yqBwLVHpLR.EFVSO9VFqTOmOEYpM4rqiCB7VESh3Hq9S3Em', 'Admin', 'Principal', 'ADMIN', 'ACTIVE', 'VERIFIED', NOW(), NOW(), NOW(), true),
('superadmin@ismail-platform.com', '+2250701234568', '$2a$12$LQv3c1yqBwLVHpLR.EFVSO9VFqTOmOEYpM4rqiCB7VESh3Hq9S3Em', 'Super', 'Admin', 'ADMIN', 'ACTIVE', 'VERIFIED', NOW(), NOW(), NOW(), true),

-- Commerciaux
('commercial1@ismail-platform.com', '+2250701234569', '$2a$12$LQv3c1yqBwLVHpLR.EFVSO9VFqTOmOEYpM4rqiCB7VESh3Hq9S3Em', 'Aïcha', 'Traoré', 'COMMERCIAL', 'ACTIVE', 'VERIFIED', NOW(), NOW(), NOW(), true),
('commercial2@ismail-platform.com', '+2250701234570', '$2a$12$LQv3c1yqBwLVHpLR.EFVSO9VFqTOmOEYpM4rqiCB7VESh3Hq9S3Em', 'Mamadou', 'Koné', 'COMMERCIAL', 'ACTIVE', 'VERIFIED', NOW(), NOW(), NOW(), true),

-- Partenaires (Prestataires)
('plombier@ismail-platform.com', '+2250701234571', '$2a$12$LQv3c1yqBwLVHpLR.EFVSO9VFqTOmOEYpM4rqiCB7VESh3Hq9S3Em', 'Kofi', 'Asante', 'PARTNER', 'ACTIVE', 'VERIFIED', NOW(), NOW(), NOW(), true),
('electricien@ismail-platform.com', '+2250701234572', '$2a$12$LQv3c1yqBwLVHpLR.EFVSO9VFqTOmOEYpM4rqiCB7VESh3Hq9S3Em', 'Ibrahim', 'Diallo', 'PARTNER', 'ACTIVE', 'VERIFIED', NOW(), NOW(), NOW(), true),
('menage@ismail-platform.com', '+2250701234573', '$2a$12$LQv3c1yqBwLVHpLR.EFVSO9VFqTOmOEYpM4rqiCB7VESh3Hq9S3Em', 'Fatima', 'Ouattara', 'PARTNER', 'ACTIVE', 'VERIFIED', NOW(), NOW(), NOW(), true),
('marchand@ismail-platform.com', '+2250701234574', '$2a$12$LQv3c1yqBwLVHpLR.EFVSO9VFqTOmOEYpM4rqiCB7VESh3Hq9S3Em', 'Kwame', 'Nkrumah', 'PARTNER', 'ACTIVE', 'VERIFIED', NOW(), NOW(), NOW(), true),

-- Clients
('client1@ismail-platform.com', '+2250701234575', '$2a$12$LQv3c1yqBwLVHpLR.EFVSO9VFqTOmOEYpM4rqiCB7VESh3Hq9S3Em', 'Fatou', 'Bamba', 'CLIENT', 'ACTIVE', 'VERIFIED', NOW(), NOW(), NOW(), true),
('client2@ismail-platform.com', '+2250701234576', '$2a$12$LQv3c1yqBwLVHpLR.EFVSO9VFqTOmOEYpM4rqiCB7VESh3Hq9S3Em', 'Youssouf', 'Sanogo', 'CLIENT', 'ACTIVE', 'VERIFIED', NOW(), NOW(), NOW(), true),
('client3@ismail-platform.com', '+2250701234577', '$2a$12$LQv3c1yqBwLVHpLR.EFVSO9VFqTOmOEYpM4rqiCB7VESh3Hq9S3Em', 'Aminata', 'Coulibaly', 'CLIENT', 'ACTIVE', 'VERIFIED', NOW(), NOW(), NOW(), true)

ON CONFLICT (email) DO NOTHING;

-- =====================================================
-- PORTEFEUILLES
-- =====================================================

-- Créer des portefeuilles pour tous les utilisateurs
INSERT INTO core.wallets (user_id, balance, currency, status)
SELECT 
    id, 
    CASE 
        WHEN profile_type = 'ADMIN' THEN 10000.00
        WHEN profile_type = 'COMMERCIAL' THEN 5000.00
        WHEN profile_type = 'PARTNER' THEN 2000.00
        ELSE 1000.00
    END as balance,
    'XOF',
    'ACTIVE'
FROM core.users 
WHERE email LIKE '%@ismail-platform.com'
ON CONFLICT (user_id, currency) DO NOTHING;

-- =====================================================
-- CARTES PROFESSIONNELLES
-- =====================================================

-- Générer des cartes professionnelles pour les utilisateurs vérifiés
INSERT INTO core.professional_cards (user_id, card_number, qr_code_data, qr_code_secret, photo_url)
SELECT 
    id,
    'CARD' || LPAD((ROW_NUMBER() OVER())::TEXT, 12, '0'),
    'ISMAIL-CARD-' || id || '-' || EXTRACT(EPOCH FROM NOW())::TEXT,
    encode(gen_random_bytes(32), 'hex'),
    'https://storage.ismail-platform.com/avatars/default-' || profile_type || '.jpg'
FROM core.users 
WHERE email LIKE '%@ismail-platform.com' AND kyc_status = 'VERIFIED'
ON CONFLICT (user_id, status) DO NOTHING;

-- =====================================================
-- TRANSACTIONS DE TEST
-- =====================================================

-- Générer quelques transactions pour les portefeuilles
WITH user_wallets AS (
    SELECT w.id as wallet_id, w.user_id, w.balance, u.profile_type
    FROM core.wallets w
    JOIN core.users u ON w.user_id = u.id
    WHERE u.email LIKE '%@ismail-platform.com'
)
INSERT INTO core.transactions (
    wallet_id, transaction_type, amount, balance_before, balance_after,
    description, reference, status, processed_at
)
SELECT 
    wallet_id,
    'CREDIT',
    balance,
    0.00,
    balance,
    'Crédit initial de test',
    'TXN' || TO_CHAR(NOW(), 'YYMMDDHHMI') || LPAD((ROW_NUMBER() OVER())::TEXT, 7, '0'),
    'COMPLETED',
    NOW() - INTERVAL '1 day'
FROM user_wallets;

-- =====================================================
-- PARAMÈTRES SYSTÈME
-- =====================================================

-- Mettre à jour les paramètres système avec des valeurs de test
UPDATE core.system_parameters SET parameter_value = '25' WHERE parameter_key = 'CREDIT_TO_FCFA_RATE';
UPDATE core.system_parameters SET parameter_value = '50' WHERE parameter_key = 'MIN_CREDIT_PURCHASE';
UPDATE core.system_parameters SET parameter_value = '100' WHERE parameter_key = 'MAX_DAILY_TRANSACTIONS';

-- Ajouter des paramètres spécifiques au test
INSERT INTO core.system_parameters (parameter_key, parameter_value, parameter_type, description, category, is_public) VALUES
('TEST_MODE_ENABLED', 'true', 'BOOLEAN', 'Mode test activé', 'SYSTEM', false),
('DEMO_DATA_VERSION', '1.0', 'STRING', 'Version des données de démonstration', 'SYSTEM', false),
('NOTIFICATION_TEST_EMAIL', 'test@ismail-platform.com', 'STRING', 'Email pour tests de notification', 'NOTIFICATION', false)
ON CONFLICT (parameter_key) DO UPDATE SET parameter_value = EXCLUDED.parameter_value;

-- =====================================================
-- DONNÉES GÉOGRAPHIQUES DE TEST
-- =====================================================

-- Créer une table temporaire pour les coordonnées des villes ivoiriennes
CREATE TEMP TABLE temp_cities (
    name VARCHAR(100),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8)
);

INSERT INTO temp_cities VALUES
('Abidjan', 5.3599517, -4.0082563),
('Bouaké', 7.6843, -5.0295),
('Daloa', 6.8775, -6.4503),
('Yamoussoukro', 6.8276, -5.2893),
('San-Pédro', 4.7485, -6.6363),
('Korhogo', 9.4580, -5.6300),
('Man', 7.4125, -7.5544),
('Divo', 5.8370, -5.3570),
('Gagnoa', 6.1319, -5.9506),
('Abengourou', 6.7294, -3.4969);

-- =====================================================
-- PRESTATAIRES DE SERVICES
-- =====================================================

-- Créer des prestataires de services avec géolocalisation
INSERT INTO business.service_providers (
    user_id, business_name, business_type, category, subcategory,
    description, location, service_radius, hourly_rate, minimum_charge,
    rating, total_reviews, is_verified, is_active
)
SELECT 
    u.id,
    CASE 
        WHEN u.email = 'plombier@ismail-platform.com' THEN 'Plomberie Kofi Services'
        WHEN u.email = 'electricien@ismail-platform.com' THEN 'Électricité Ibrahim Pro'
        WHEN u.email = 'menage@ismail-platform.com' THEN 'Ménage Fatima Clean'
        ELSE 'Service ' || u.first_name
    END,
    'SERVICE',
    CASE 
        WHEN u.email = 'plombier@ismail-platform.com' THEN 'PLOMBERIE'
        WHEN u.email = 'electricien@ismail-platform.com' THEN 'ELECTRICITE'
        WHEN u.email = 'menage@ismail-platform.com' THEN 'MENAGE'
        ELSE 'AUTRE'
    END,
    CASE 
        WHEN u.email = 'plombier@ismail-platform.com' THEN 'REPARATION'
        WHEN u.email = 'electricien@ismail-platform.com' THEN 'INSTALLATION'
        WHEN u.email = 'menage@ismail-platform.com' THEN 'NETTOYAGE'
        ELSE 'GENERAL'
    END,
    CASE 
        WHEN u.email = 'plombier@ismail-platform.com' THEN 'Spécialiste en plomberie résidentielle et commerciale. Intervention rapide 24h/24.'
        WHEN u.email = 'electricien@ismail-platform.com' THEN 'Installation électrique, dépannage et mise aux normes. Électricien certifié.'
        WHEN u.email = 'menage@ismail-platform.com' THEN 'Service de ménage professionnel pour particuliers et entreprises.'
        ELSE 'Service professionnel de qualité'
    END,
    ST_SetSRID(ST_MakePoint(c.longitude, c.latitude), 4326),
    15, -- rayon de service en km
    CASE 
        WHEN u.email = 'plombier@ismail-platform.com' THEN 25.00
        WHEN u.email = 'electricien@ismail-platform.com' THEN 30.00
        WHEN u.email = 'menage@ismail-platform.com' THEN 15.00
        ELSE 20.00
    END,
    CASE 
        WHEN u.email = 'plombier@ismail-platform.com' THEN 50.00
        WHEN u.email = 'electricien@ismail-platform.com' THEN 75.00
        WHEN u.email = 'menage@ismail-platform.com' THEN 30.00
        ELSE 40.00
    END,
    4.5 + (RANDOM() * 0.5), -- rating entre 4.5 et 5.0
    (RANDOM() * 50 + 10)::INTEGER, -- entre 10 et 60 avis
    true,
    true
FROM core.users u
CROSS JOIN temp_cities c
WHERE u.profile_type = 'PARTNER' 
  AND u.email LIKE '%@ismail-platform.com'
  AND c.name = 'Abidjan' -- Tous les prestataires à Abidjan pour les tests
ON CONFLICT (user_id) DO NOTHING;

-- =====================================================
-- BIENS IMMOBILIERS DE TEST
-- =====================================================

-- Créer quelques biens immobiliers
INSERT INTO business.real_estate_properties (
    owner_id, property_type, transaction_type, title, description,
    location, address, city, district, surface_area, rooms_count,
    bedrooms_count, bathrooms_count, price, is_furnished, status
)
SELECT 
    u.id,
    (ARRAY['APARTMENT', 'HOUSE', 'OFFICE'])[floor(random() * 3 + 1)],
    (ARRAY['RENT', 'SALE'])[floor(random() * 2 + 1)],
    'Propriété ' || u.first_name || ' - ' || c.name,
    'Belle propriété située dans un quartier calme et sécurisé. Proche des commodités.',
    ST_SetSRID(ST_MakePoint(
        c.longitude + (RANDOM() - 0.5) * 0.1, 
        c.latitude + (RANDOM() - 0.5) * 0.1
    ), 4326),
    'Rue de la ' || c.name || ', Quartier Résidentiel',
    c.name,
    'Centre-ville',
    (RANDOM() * 100 + 50)::DECIMAL(8,2), -- entre 50 et 150 m²
    (RANDOM() * 4 + 2)::INTEGER, -- entre 2 et 6 pièces
    (RANDOM() * 3 + 1)::INTEGER, -- entre 1 et 4 chambres
    (RANDOM() * 2 + 1)::INTEGER, -- entre 1 et 3 salles de bain
    (RANDOM() * 500000 + 100000)::DECIMAL(15,2), -- entre 100K et 600K
    RANDOM() > 0.5,
    'AVAILABLE'
FROM core.users u
CROSS JOIN temp_cities c
WHERE u.profile_type = 'PARTNER' 
  AND u.email LIKE '%@ismail-platform.com'
  AND RANDOM() > 0.5 -- Seulement 50% des partenaires ont des biens
LIMIT 5;

-- =====================================================
-- COMMISSIONS DE TEST
-- =====================================================

-- Générer quelques commissions pour les commerciaux
INSERT INTO core.commissions (
    commercial_id, partner_id, commission_type, base_amount,
    commission_rate, commission_amount, period_start, period_end, status
)
SELECT 
    c.id as commercial_id,
    p.id as partner_id,
    'DIRECT',
    (RANDOM() * 1000 + 100)::DECIMAL(15,2), -- montant de base
    0.04, -- 4% de commission
    (RANDOM() * 1000 + 100)::DECIMAL(15,2) * 0.04, -- commission calculée
    DATE_TRUNC('month', CURRENT_DATE),
    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 day',
    'CALCULATED'
FROM core.users c
CROSS JOIN core.users p
WHERE c.profile_type = 'COMMERCIAL' 
  AND p.profile_type = 'PARTNER'
  AND c.email LIKE '%@ismail-platform.com'
  AND p.email LIKE '%@ismail-platform.com'
  AND RANDOM() > 0.3 -- 70% de chance de commission
LIMIT 10;

-- =====================================================
-- NETTOYAGE
-- =====================================================

-- Supprimer la table temporaire
DROP TABLE temp_cities;

-- =====================================================
-- MISE À JOUR DES STATISTIQUES
-- =====================================================

-- Mettre à jour les statistiques pour optimiser les requêtes
ANALYZE core.users;
ANALYZE core.wallets;
ANALYZE core.transactions;
ANALYZE core.commissions;
ANALYZE business.service_providers;
ANALYZE business.real_estate_properties;

-- =====================================================
-- VÉRIFICATION DES DONNÉES
-- =====================================================

-- Afficher un résumé des données insérées
DO $$
DECLARE
    user_count INTEGER;
    wallet_count INTEGER;
    transaction_count INTEGER;
    provider_count INTEGER;
    property_count INTEGER;
    commission_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM core.users WHERE email LIKE '%@ismail-platform.com';
    SELECT COUNT(*) INTO wallet_count FROM core.wallets w JOIN core.users u ON w.user_id = u.id WHERE u.email LIKE '%@ismail-platform.com';
    SELECT COUNT(*) INTO transaction_count FROM core.transactions t JOIN core.wallets w ON t.wallet_id = w.id JOIN core.users u ON w.user_id = u.id WHERE u.email LIKE '%@ismail-platform.com';
    SELECT COUNT(*) INTO provider_count FROM business.service_providers sp JOIN core.users u ON sp.user_id = u.id WHERE u.email LIKE '%@ismail-platform.com';
    SELECT COUNT(*) INTO property_count FROM business.real_estate_properties rp JOIN core.users u ON rp.owner_id = u.id WHERE u.email LIKE '%@ismail-platform.com';
    SELECT COUNT(*) INTO commission_count FROM core.commissions c JOIN core.users u ON c.commercial_id = u.id WHERE u.email LIKE '%@ismail-platform.com';
    
    RAISE NOTICE '=== DONNÉES DE TEST INSÉRÉES ===';
    RAISE NOTICE 'Utilisateurs: %', user_count;
    RAISE NOTICE 'Portefeuilles: %', wallet_count;
    RAISE NOTICE 'Transactions: %', transaction_count;
    RAISE NOTICE 'Prestataires: %', provider_count;
    RAISE NOTICE 'Biens immobiliers: %', property_count;
    RAISE NOTICE 'Commissions: %', commission_count;
    RAISE NOTICE '================================';
END $$;
