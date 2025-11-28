-- Initialize PostgreSQL for Hive Metastore
-- This script runs automatically when the PostgreSQL container starts for the first time
--
-- IMPORTANT: The following are already created by PostgreSQL environment variables:
--   - Database: Created via POSTGRES_DB=${HIVE_METASTORE_DB:-hive_metastore}
--   - User:     Created via POSTGRES_USER=${HIVE_METASTORE_USER:-hive}
--   - Password: Set via POSTGRES_PASSWORD=${HIVE_METASTORE_PASSWORD:-hive}
--
-- This script only needs to:
--   1. Set appropriate permissions on the database and schema
--   2. Configure default privileges for future objects
--   3. Enable useful extensions

-- Connect to the hive_metastore database
\c hive_metastore;

-- Grant schema privileges to the hive user (created via POSTGRES_USER env var)
GRANT ALL ON SCHEMA public TO hive;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO hive;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO hive;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO hive;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO hive;

-- Enable necessary extensions for better performance
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;