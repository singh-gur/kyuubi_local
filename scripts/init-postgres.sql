-- Initialize PostgreSQL for Hive Metastore
-- This script runs when the PostgreSQL container starts

-- Create database if it doesn't exist
CREATE DATABASE hive_metastore;

-- Create user if it doesn't exist
CREATE USER hive WITH PASSWORD 'hive';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE hive_metastore TO hive;

-- Connect to the database and create schema
\c hive_metastore;

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO hive;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO hive;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO hive;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO hive;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO hive;