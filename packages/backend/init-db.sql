-- Grant permissions to the user for the public schema
-- Note: This runs as the postgres superuser (created automatically)
GRANT ALL ON SCHEMA public TO focura_user;
GRANT ALL PRIVILEGES ON DATABASE focura TO focura_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO focura_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO focura_user;
ALTER USER focura_user WITH SUPERUSER;

