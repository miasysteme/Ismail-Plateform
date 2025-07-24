-- Script d'initialisation PostgreSQL - Plateforme ISMAIL
-- Création des bases de données, utilisateurs et extensions

-- =====================================================
-- CONFIGURATION GLOBALE
-- =====================================================

-- Extensions requises
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- Configuration des paramètres globaux
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements,postgis';
ALTER SYSTEM SET max_connections = 200;
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET work_mem = '4MB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;

-- =====================================================
-- CRÉATION DES BASES DE DONNÉES
-- =====================================================

-- Base de données principale ISMAIL
CREATE DATABASE ismail_main
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

-- Base de données Kong (API Gateway)
CREATE DATABASE kong
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = 50;

-- Base de données pour les tests
CREATE DATABASE ismail_test
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = 20;

-- =====================================================
-- CRÉATION DES UTILISATEURS
-- =====================================================

-- Utilisateur pour l'application principale
CREATE USER ismail_app WITH
    LOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    INHERIT
    NOREPLICATION
    CONNECTION LIMIT 50
    PASSWORD 'IsmaIl2024!App#Secure';

-- Utilisateur pour Kong
CREATE USER kong_user WITH
    LOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    INHERIT
    NOREPLICATION
    CONNECTION LIMIT 20
    PASSWORD 'Kong2024!Secure#Gateway';

-- Utilisateur pour les backups
CREATE USER ismail_backup WITH
    LOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    INHERIT
    NOREPLICATION
    CONNECTION LIMIT 5
    PASSWORD 'Backup2024!Secure#ISMAIL';

-- Utilisateur en lecture seule pour les analytics
CREATE USER ismail_readonly WITH
    LOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    INHERIT
    NOREPLICATION
    CONNECTION LIMIT 10
    PASSWORD 'ReadOnly2024!Analytics#ISMAIL';

-- =====================================================
-- CONFIGURATION BASE ISMAIL_MAIN
-- =====================================================

\c ismail_main;

-- Extensions spécifiques à la base principale
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- Schémas applicatifs
CREATE SCHEMA IF NOT EXISTS core AUTHORIZATION ismail_app;
CREATE SCHEMA IF NOT EXISTS business AUTHORIZATION ismail_app;
CREATE SCHEMA IF NOT EXISTS analytics AUTHORIZATION ismail_app;
CREATE SCHEMA IF NOT EXISTS audit AUTHORIZATION ismail_app;

-- Permissions pour l'utilisateur application
GRANT CONNECT ON DATABASE ismail_main TO ismail_app;
GRANT USAGE ON SCHEMA public TO ismail_app;
GRANT USAGE ON SCHEMA core TO ismail_app;
GRANT USAGE ON SCHEMA business TO ismail_app;
GRANT USAGE ON SCHEMA analytics TO ismail_app;
GRANT USAGE ON SCHEMA audit TO ismail_app;

-- Permissions complètes sur les schémas applicatifs
GRANT ALL PRIVILEGES ON SCHEMA core TO ismail_app;
GRANT ALL PRIVILEGES ON SCHEMA business TO ismail_app;
GRANT ALL PRIVILEGES ON SCHEMA analytics TO ismail_app;
GRANT ALL PRIVILEGES ON SCHEMA audit TO ismail_app;

-- Permissions par défaut pour les nouvelles tables
ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT ALL ON TABLES TO ismail_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA business GRANT ALL ON TABLES TO ismail_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics GRANT ALL ON TABLES TO ismail_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA audit GRANT ALL ON TABLES TO ismail_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT ALL ON SEQUENCES TO ismail_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA business GRANT ALL ON SEQUENCES TO ismail_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics GRANT ALL ON SEQUENCES TO ismail_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA audit GRANT ALL ON SEQUENCES TO ismail_app;

-- Permissions lecture seule pour analytics
GRANT CONNECT ON DATABASE ismail_main TO ismail_readonly;
GRANT USAGE ON SCHEMA core TO ismail_readonly;
GRANT USAGE ON SCHEMA business TO ismail_readonly;
GRANT USAGE ON SCHEMA analytics TO ismail_readonly;
GRANT USAGE ON SCHEMA audit TO ismail_readonly;

ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT SELECT ON TABLES TO ismail_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA business GRANT SELECT ON TABLES TO ismail_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics GRANT SELECT ON TABLES TO ismail_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA audit GRANT SELECT ON TABLES TO ismail_readonly;

-- =====================================================
-- FONCTIONS UTILITAIRES
-- =====================================================

-- Fonction pour générer des IDs ISMAIL uniques
CREATE OR REPLACE FUNCTION core.generate_ismail_id(
    country_code VARCHAR(2) DEFAULT 'CI',
    user_type VARCHAR(2) DEFAULT 'CL'
) RETURNS VARCHAR(16) AS $$
DECLARE
    date_part VARCHAR(6);
    random_part VARCHAR(4);
    result VARCHAR(16);
BEGIN
    -- Format: CCYYMMDD-XXXX-UL
    date_part := TO_CHAR(CURRENT_DATE, 'YYMMDD');
    random_part := UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 4));
    
    result := country_code || date_part || '-' || random_part || '-' || user_type;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour chiffrer les données sensibles
CREATE OR REPLACE FUNCTION core.encrypt_sensitive_data(
    data TEXT,
    key_id TEXT DEFAULT 'default'
) RETURNS TEXT AS $$
BEGIN
    RETURN encode(pgp_sym_encrypt(data, key_id), 'base64');
END;
$$ LANGUAGE plpgsql;

-- Fonction pour déchiffrer les données sensibles
CREATE OR REPLACE FUNCTION core.decrypt_sensitive_data(
    encrypted_data TEXT,
    key_id TEXT DEFAULT 'default'
) RETURNS TEXT AS $$
BEGIN
    RETURN pgp_sym_decrypt(decode(encrypted_data, 'base64'), key_id);
END;
$$ LANGUAGE plpgsql;

-- Fonction pour l'audit automatique
CREATE OR REPLACE FUNCTION audit.audit_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit.audit_log (
            table_name,
            operation,
            new_values,
            user_id,
            timestamp
        ) VALUES (
            TG_TABLE_NAME,
            TG_OP,
            row_to_json(NEW),
            current_setting('app.current_user_id', true),
            NOW()
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit.audit_log (
            table_name,
            operation,
            old_values,
            new_values,
            user_id,
            timestamp
        ) VALUES (
            TG_TABLE_NAME,
            TG_OP,
            row_to_json(OLD),
            row_to_json(NEW),
            current_setting('app.current_user_id', true),
            NOW()
        );
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit.audit_log (
            table_name,
            operation,
            old_values,
            user_id,
            timestamp
        ) VALUES (
            TG_TABLE_NAME,
            TG_OP,
            row_to_json(OLD),
            current_setting('app.current_user_id', true),
            NOW()
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TABLES D'AUDIT
-- =====================================================

-- Table principale d'audit
CREATE TABLE audit.audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(100) NOT NULL,
    operation VARCHAR(10) NOT NULL,
    old_values JSONB,
    new_values JSONB,
    user_id VARCHAR(50),
    timestamp TIMESTAMP DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT
);

-- Index pour performance
CREATE INDEX idx_audit_log_table_name ON audit.audit_log(table_name);
CREATE INDEX idx_audit_log_timestamp ON audit.audit_log(timestamp);
CREATE INDEX idx_audit_log_user_id ON audit.audit_log(user_id);
CREATE INDEX idx_audit_log_operation ON audit.audit_log(operation);

-- Partitioning par mois pour l'audit
CREATE TABLE audit.audit_log_y2024m01 PARTITION OF audit.audit_log
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE audit.audit_log_y2024m02 PARTITION OF audit.audit_log
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- =====================================================
-- CONFIGURATION KONG
-- =====================================================

\c kong;

-- Permissions pour Kong
GRANT ALL PRIVILEGES ON DATABASE kong TO kong_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO kong_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO kong_user;

-- =====================================================
-- CONFIGURATION MONITORING
-- =====================================================

\c ismail_main;

-- Vue pour monitoring des connexions
CREATE OR REPLACE VIEW analytics.connection_stats AS
SELECT 
    datname as database_name,
    usename as username,
    client_addr,
    state,
    COUNT(*) as connection_count,
    MAX(backend_start) as latest_connection
FROM pg_stat_activity 
WHERE datname IS NOT NULL
GROUP BY datname, usename, client_addr, state;

-- Vue pour monitoring des requêtes lentes
CREATE OR REPLACE VIEW analytics.slow_queries AS
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    rows,
    100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent
FROM pg_stat_statements 
WHERE mean_time > 1000  -- Requêtes > 1 seconde
ORDER BY mean_time DESC;

-- Vue pour monitoring de l'espace disque
CREATE OR REPLACE VIEW analytics.database_size AS
SELECT 
    datname as database_name,
    pg_size_pretty(pg_database_size(datname)) as size,
    pg_database_size(datname) as size_bytes
FROM pg_database 
WHERE datname NOT IN ('template0', 'template1', 'postgres')
ORDER BY pg_database_size(datname) DESC;

-- =====================================================
-- CONFIGURATION BACKUP
-- =====================================================

-- Permissions pour les backups
GRANT CONNECT ON DATABASE ismail_main TO ismail_backup;
GRANT USAGE ON SCHEMA core TO ismail_backup;
GRANT USAGE ON SCHEMA business TO ismail_backup;
GRANT USAGE ON SCHEMA analytics TO ismail_backup;
GRANT USAGE ON SCHEMA audit TO ismail_backup;

GRANT SELECT ON ALL TABLES IN SCHEMA core TO ismail_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA business TO ismail_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO ismail_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA audit TO ismail_backup;

-- =====================================================
-- OPTIMISATIONS PERFORMANCE
-- =====================================================

-- Configuration des statistiques automatiques
ALTER DATABASE ismail_main SET log_statement_stats = off;
ALTER DATABASE ismail_main SET log_parser_stats = off;
ALTER DATABASE ismail_main SET log_planner_stats = off;
ALTER DATABASE ismail_main SET log_executor_stats = off;

-- Configuration du logging
ALTER DATABASE ismail_main SET log_min_duration_statement = 1000;
ALTER DATABASE ismail_main SET log_checkpoints = on;
ALTER DATABASE ismail_main SET log_connections = on;
ALTER DATABASE ismail_main SET log_disconnections = on;
ALTER DATABASE ismail_main SET log_lock_waits = on;

-- Configuration des timeouts
ALTER DATABASE ismail_main SET statement_timeout = '30s';
ALTER DATABASE ismail_main SET lock_timeout = '10s';
ALTER DATABASE ismail_main SET idle_in_transaction_session_timeout = '5min';

-- =====================================================
-- FINALISATION
-- =====================================================

-- Mise à jour des statistiques
ANALYZE;

-- Message de confirmation
DO $$
BEGIN
    RAISE NOTICE 'Base de données ISMAIL initialisée avec succès!';
    RAISE NOTICE 'Bases créées: ismail_main, kong, ismail_test';
    RAISE NOTICE 'Utilisateurs créés: ismail_app, kong_user, ismail_backup, ismail_readonly';
    RAISE NOTICE 'Extensions installées: uuid-ossp, pgcrypto, postgis, pg_stat_statements';
    RAISE NOTICE 'Schémas créés: core, business, analytics, audit';
END $$;
