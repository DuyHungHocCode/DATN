-- Grant permissions in DB_BCA
USE [DB_BCA];
GO

-- Permissions for bca_admin_user (Full control)
ALTER ROLE db_owner ADD MEMBER [bca_admin_user];
GO

-- Permissions for bca_reader_user (Read-only access)
GRANT SELECT ON SCHEMA :: [BCA] TO [bca_reader_user];
GRANT SELECT ON SCHEMA :: [Reference] TO [bca_reader_user];
GRANT SELECT ON SCHEMA :: [Audit] TO [bca_reader_user];
GRANT EXECUTE ON SCHEMA :: [API_Internal] TO [bca_reader_user];
GO

-- Permissions for bca_writer_user (Read/Write access)
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA :: [BCA] TO [bca_writer_user];
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA :: [Reference] TO [bca_writer_user];
GRANT EXECUTE ON SCHEMA :: [API_Internal] TO [bca_writer_user];
GO

-- Permissions for api_service_user (Execute internal APIs, Select data)
GRANT EXECUTE ON SCHEMA :: [API_Internal] TO [api_service_user];
GRANT SELECT ON SCHEMA :: [BCA] TO [api_service_user];
GRANT SELECT ON SCHEMA :: [Reference] TO [api_service_user];
-- Add INSERT/UPDATE/DELETE if the API service needs direct table access (less common with API_Internal schema)
-- GRANT INSERT, UPDATE, DELETE ON SCHEMA :: [BCA] TO [api_service_user];
GO


-- Grant permissions in DB_BTP
USE [DB_BTP];
GO

-- Permissions for btp_admin_user (Full control)
ALTER ROLE db_owner ADD MEMBER [btp_admin_user];
GO

-- Permissions for btp_reader_user (Read-only access)
GRANT SELECT ON SCHEMA :: [BTP] TO [btp_reader_user];
GRANT SELECT ON SCHEMA :: [Reference] TO [btp_reader_user];
GRANT SELECT ON SCHEMA :: [Audit] TO [btp_reader_user];
GRANT EXECUTE ON SCHEMA :: [API_Internal] TO [btp_reader_user];
GO

-- Permissions for btp_writer_user (Read/Write access)
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA :: [BTP] TO [btp_writer_user];
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA :: [Reference] TO [btp_writer_user];
GRANT EXECUTE ON SCHEMA :: [API_Internal] TO [btp_writer_user];
GO

-- Permissions for api_service_user (Execute internal APIs, Select data)
GRANT EXECUTE ON SCHEMA :: [API_Internal] TO [api_service_user];
GRANT SELECT ON SCHEMA :: [BTP] TO [api_service_user];
GRANT SELECT ON SCHEMA :: [Reference] TO [api_service_user];
-- Add INSERT/UPDATE/DELETE if the API service needs direct table access
-- GRANT INSERT, UPDATE, DELETE ON SCHEMA :: [BTP] TO [api_service_user];
GO

