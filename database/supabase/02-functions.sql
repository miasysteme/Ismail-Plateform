-- ISMAIL Platform - Fonctions et Triggers Supabase
-- Fonctions métier et automatisations

-- =====================================================
-- FONCTIONS UTILITAIRES
-- =====================================================

-- Fonction pour générer un ID ISMAIL unique
CREATE OR REPLACE FUNCTION ismail.generate_ismail_id(
    p_country_code VARCHAR(2) DEFAULT 'CI',
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

-- Fonction pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION ismail.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Fonction pour créer un portefeuille par défaut
CREATE OR REPLACE FUNCTION ismail.create_default_wallet()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Créer un portefeuille XOF par défaut
    INSERT INTO ismail.wallets (user_id, currency, balance)
    VALUES (NEW.id, NEW.currency, 0.00);
    
    RETURN NEW;
END;
$$;

-- Fonction pour générer une référence de transaction unique
CREATE OR REPLACE FUNCTION ismail.generate_transaction_reference(
    p_type ismail.transaction_type
)
RETURNS VARCHAR(100)
LANGUAGE plpgsql
AS $$
DECLARE
    v_prefix VARCHAR(3);
    v_timestamp VARCHAR(14);
    v_random VARCHAR(6);
    v_reference VARCHAR(100);
    v_exists BOOLEAN;
BEGIN
    -- Préfixe selon le type
    v_prefix := CASE p_type
        WHEN 'DEPOSIT' THEN 'DEP'
        WHEN 'WITHDRAWAL' THEN 'WDR'
        WHEN 'TRANSFER' THEN 'TRF'
        WHEN 'PAYMENT' THEN 'PAY'
        WHEN 'COMMISSION' THEN 'COM'
        WHEN 'REFUND' THEN 'REF'
        WHEN 'FEE' THEN 'FEE'
        ELSE 'TXN'
    END;
    
    -- Timestamp (YYYYMMDDHHMMSS)
    v_timestamp := TO_CHAR(NOW(), 'YYYYMMDDHH24MISS');
    
    -- Générer une référence unique
    LOOP
        -- Partie aléatoire
        v_random := UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 6));
        
        -- Construire la référence
        v_reference := v_prefix || v_timestamp || v_random;
        
        -- Vérifier l'unicité
        SELECT EXISTS(
            SELECT 1 FROM ismail.transactions WHERE reference = v_reference
        ) INTO v_exists;
        
        EXIT WHEN NOT v_exists;
    END LOOP;
    
    RETURN v_reference;
END;
$$;

-- Fonction pour mettre à jour le solde du portefeuille
CREATE OR REPLACE FUNCTION ismail.update_wallet_balance()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_wallet_balance DECIMAL(15,2);
    v_new_balance DECIMAL(15,2);
BEGIN
    -- Récupérer le solde actuel
    SELECT balance INTO v_wallet_balance
    FROM ismail.wallets
    WHERE id = NEW.wallet_id;
    
    -- Calculer le nouveau solde selon le type de transaction
    CASE NEW.type
        WHEN 'DEPOSIT', 'REFUND', 'COMMISSION' THEN
            v_new_balance := v_wallet_balance + NEW.amount;
        WHEN 'WITHDRAWAL', 'PAYMENT', 'FEE' THEN
            v_new_balance := v_wallet_balance - NEW.amount;
        WHEN 'TRANSFER' THEN
            -- Pour les transferts, le signe dépend du contexte
            -- Ici on assume que c'est géré par l'application
            v_new_balance := v_wallet_balance + NEW.amount;
        ELSE
            v_new_balance := v_wallet_balance;
    END CASE;
    
    -- Vérifier que le solde ne devient pas négatif
    IF v_new_balance < 0 THEN
        RAISE EXCEPTION 'Solde insuffisant. Solde actuel: %, Montant: %', v_wallet_balance, NEW.amount;
    END IF;
    
    -- Mettre à jour les soldes dans la transaction
    NEW.balance_before := v_wallet_balance;
    NEW.balance_after := v_new_balance;
    
    -- Mettre à jour le solde du portefeuille si la transaction est complétée
    IF NEW.status = 'COMPLETED' THEN
        UPDATE ismail.wallets
        SET balance = v_new_balance, updated_at = NOW()
        WHERE id = NEW.wallet_id;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Fonction pour créer un log d'audit
CREATE OR REPLACE FUNCTION ismail.create_audit_log()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id UUID;
    v_action VARCHAR(100);
    v_entity_type VARCHAR(50);
BEGIN
    -- Déterminer l'action
    IF TG_OP = 'INSERT' THEN
        v_action := 'CREATE';
    ELSIF TG_OP = 'UPDATE' THEN
        v_action := 'UPDATE';
    ELSIF TG_OP = 'DELETE' THEN
        v_action := 'DELETE';
    END IF;
    
    -- Déterminer le type d'entité
    v_entity_type := TG_TABLE_NAME;
    
    -- Récupérer l'ID utilisateur si disponible
    BEGIN
        IF TG_OP = 'DELETE' THEN
            -- Essayer d'extraire user_id de OLD
            IF TG_TABLE_NAME = 'users' THEN
                v_user_id := OLD.id;
            ELSE
                v_user_id := (row_to_json(OLD)->>'user_id')::uuid;
            END IF;
        ELSE
            -- Essayer d'extraire user_id de NEW
            IF TG_TABLE_NAME = 'users' THEN
                v_user_id := NEW.id;
            ELSE
                v_user_id := (row_to_json(NEW)->>'user_id')::uuid;
            END IF;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        -- Si pas de user_id disponible, utiliser NULL
        v_user_id := NULL;
    END;
    
    -- Créer le log d'audit
    INSERT INTO ismail.audit_logs (
        user_id,
        action,
        entity_type,
        entity_id,
        old_values,
        new_values,
        ip_address,
        session_id
    ) VALUES (
        v_user_id,
        v_action,
        v_entity_type,
        COALESCE(NEW.id, OLD.id),
        CASE WHEN TG_OP = 'DELETE' THEN row_to_json(OLD) ELSE NULL END,
        CASE WHEN TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN row_to_json(NEW) ELSE NULL END,
        inet_client_addr(),
        CASE
            WHEN current_setting('app.session_id', true) IS NOT NULL
                AND current_setting('app.session_id', true) != ''
            THEN current_setting('app.session_id', true)::UUID
            ELSE NULL
        END
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$$;

-- Fonction pour nettoyer les sessions expirées
CREATE OR REPLACE FUNCTION ismail.cleanup_expired_sessions()
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    DELETE FROM ismail.user_sessions
    WHERE expires_at < NOW() OR is_active = FALSE;
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RETURN v_deleted_count;
END;
$$;

-- Fonction pour calculer les statistiques utilisateur
CREATE OR REPLACE FUNCTION ismail.get_user_stats(p_user_id UUID)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    v_stats JSON;
BEGIN
    SELECT json_build_object(
        'total_transactions', COUNT(*),
        'total_amount', COALESCE(SUM(amount), 0),
        'last_transaction', MAX(created_at),
        'wallet_balance', (
            SELECT balance 
            FROM ismail.wallets 
            WHERE user_id = p_user_id AND currency = 'XOF'
            LIMIT 1
        )
    ) INTO v_stats
    FROM ismail.transactions t
    JOIN ismail.wallets w ON t.wallet_id = w.id
    WHERE w.user_id = p_user_id;
    
    RETURN v_stats;
END;
$$;

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Supprimer les triggers existants s'ils existent
DROP TRIGGER IF EXISTS trigger_users_updated_at ON ismail.users;
DROP TRIGGER IF EXISTS trigger_wallets_updated_at ON ismail.wallets;
DROP TRIGGER IF EXISTS trigger_transactions_updated_at ON ismail.transactions;
DROP TRIGGER IF EXISTS trigger_create_default_wallet ON ismail.users;
DROP TRIGGER IF EXISTS trigger_update_wallet_balance ON ismail.transactions;
DROP TRIGGER IF EXISTS trigger_audit_users ON ismail.users;
DROP TRIGGER IF EXISTS trigger_audit_transactions ON ismail.transactions;

-- Trigger pour updated_at sur users
CREATE TRIGGER trigger_users_updated_at
    BEFORE UPDATE ON ismail.users
    FOR EACH ROW
    EXECUTE FUNCTION ismail.update_updated_at_column();

-- Trigger pour updated_at sur wallets
CREATE TRIGGER trigger_wallets_updated_at
    BEFORE UPDATE ON ismail.wallets
    FOR EACH ROW
    EXECUTE FUNCTION ismail.update_updated_at_column();

-- Trigger pour updated_at sur transactions
CREATE TRIGGER trigger_transactions_updated_at
    BEFORE UPDATE ON ismail.transactions
    FOR EACH ROW
    EXECUTE FUNCTION ismail.update_updated_at_column();

-- Trigger pour créer un portefeuille par défaut
CREATE TRIGGER trigger_create_default_wallet
    AFTER INSERT ON ismail.users
    FOR EACH ROW
    EXECUTE FUNCTION ismail.create_default_wallet();

-- Trigger pour mettre à jour le solde du portefeuille
CREATE TRIGGER trigger_update_wallet_balance
    BEFORE INSERT OR UPDATE ON ismail.transactions
    FOR EACH ROW
    EXECUTE FUNCTION ismail.update_wallet_balance();

-- Triggers d'audit
CREATE TRIGGER trigger_audit_users
    AFTER INSERT OR UPDATE OR DELETE ON ismail.users
    FOR EACH ROW
    EXECUTE FUNCTION ismail.create_audit_log();

CREATE TRIGGER trigger_audit_transactions
    AFTER INSERT OR UPDATE OR DELETE ON ismail.transactions
    FOR EACH ROW
    EXECUTE FUNCTION ismail.create_audit_log();

-- =====================================================
-- VUES UTILES
-- =====================================================

-- Vue des utilisateurs avec leurs portefeuilles
CREATE OR REPLACE VIEW ismail.users_with_wallets AS
SELECT 
    u.id,
    u.ismail_id,
    u.email,
    u.first_name,
    u.last_name,
    u.profile_type,
    u.status,
    u.kyc_status,
    u.country,
    u.created_at,
    w.balance,
    w.currency,
    w.daily_limit,
    w.monthly_limit
FROM ismail.users u
LEFT JOIN ismail.wallets w ON u.id = w.user_id;

-- Vue des transactions avec détails utilisateur
CREATE OR REPLACE VIEW ismail.transactions_with_user AS
SELECT 
    t.id,
    t.reference,
    t.type,
    t.amount,
    t.currency,
    t.status,
    t.payment_method,
    t.description,
    t.created_at,
    u.ismail_id,
    u.email,
    u.first_name,
    u.last_name
FROM ismail.transactions t
JOIN ismail.wallets w ON t.wallet_id = w.id
JOIN ismail.users u ON w.user_id = u.id;

-- Vue des statistiques par pays
CREATE OR REPLACE VIEW ismail.stats_by_country AS
SELECT
    u.country,
    COUNT(*) as total_users,
    COUNT(CASE WHEN u.status = 'ACTIVE' THEN 1 END) as active_users,
    COUNT(CASE WHEN u.kyc_status = 'APPROVED' THEN 1 END) as verified_users,
    COUNT(CASE WHEN u.profile_type = 'PARTNER' THEN 1 END) as partners,
    AVG(CASE WHEN w.currency = 'XOF' THEN w.balance END) as avg_balance_xof
FROM ismail.users u
LEFT JOIN ismail.wallets w ON u.id = w.user_id
GROUP BY u.country
ORDER BY total_users DESC;

-- =====================================================
-- POLITIQUES RLS (ROW LEVEL SECURITY)
-- =====================================================

-- Supprimer les politiques existantes
DROP POLICY IF EXISTS "Users can view own data" ON ismail.users;
DROP POLICY IF EXISTS "Users can update own data" ON ismail.users;
DROP POLICY IF EXISTS "Users can view own wallets" ON ismail.wallets;
DROP POLICY IF EXISTS "Users can update own wallets" ON ismail.wallets;
DROP POLICY IF EXISTS "Users can view own transactions" ON ismail.transactions;
DROP POLICY IF EXISTS "Users can view own sessions" ON ismail.user_sessions;
DROP POLICY IF EXISTS "Users can update own sessions" ON ismail.user_sessions;
DROP POLICY IF EXISTS "Users can view own cards" ON ismail.professional_cards;
DROP POLICY IF EXISTS "Admins have full access to users" ON ismail.users;

-- Activer RLS sur toutes les tables
ALTER TABLE ismail.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE ismail.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ismail.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ismail.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ismail.professional_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE ismail.audit_logs ENABLE ROW LEVEL SECURITY;

-- Politiques pour les utilisateurs
CREATE POLICY "Users can view own data" ON ismail.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON ismail.users
    FOR UPDATE USING (auth.uid() = id);

-- Politiques pour les portefeuilles
CREATE POLICY "Users can view own wallets" ON ismail.wallets
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update own wallets" ON ismail.wallets
    FOR UPDATE USING (user_id = auth.uid());

-- Politiques pour les transactions
CREATE POLICY "Users can view own transactions" ON ismail.transactions
    FOR SELECT USING (
        wallet_id IN (
            SELECT id FROM ismail.wallets WHERE user_id = auth.uid()
        )
    );

-- Politiques pour les sessions
CREATE POLICY "Users can view own sessions" ON ismail.user_sessions
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update own sessions" ON ismail.user_sessions
    FOR UPDATE USING (user_id = auth.uid());

-- Politiques pour les cartes professionnelles
CREATE POLICY "Users can view own cards" ON ismail.professional_cards
    FOR SELECT USING (user_id = auth.uid());

-- Politiques pour les admins (accès complet)
CREATE POLICY "Admins have full access to users" ON ismail.users
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM ismail.users
            WHERE id = auth.uid() AND profile_type = 'ADMIN'
        )
    );

-- =====================================================
-- FONCTIONS D'API
-- =====================================================

-- Fonction pour l'inscription d'un utilisateur
CREATE OR REPLACE FUNCTION ismail.register_user(
    p_email VARCHAR(255),
    p_phone VARCHAR(20),
    p_password VARCHAR(255),
    p_first_name VARCHAR(100),
    p_last_name VARCHAR(100),
    p_profile_type ismail.profile_type DEFAULT 'CLIENT',
    p_country VARCHAR(2) DEFAULT 'CI'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_ismail_id VARCHAR(20);
    v_result JSON;
BEGIN
    -- Générer l'ID ISMAIL
    v_ismail_id := ismail.generate_ismail_id(p_country, p_profile_type);
    
    -- Créer l'utilisateur
    INSERT INTO ismail.users (
        ismail_id, email, phone, first_name, last_name, 
        profile_type, country, password_hash
    ) VALUES (
        v_ismail_id, p_email, p_phone, p_first_name, p_last_name,
        p_profile_type, p_country, crypt(p_password, gen_salt('bf'))
    ) RETURNING id INTO v_user_id;
    
    -- Retourner le résultat
    v_result := json_build_object(
        'success', true,
        'user_id', v_user_id,
        'ismail_id', v_ismail_id,
        'message', 'Utilisateur créé avec succès'
    );
    
    RETURN v_result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'message', 'Erreur lors de la création de l''utilisateur'
    );
END;
$$;
