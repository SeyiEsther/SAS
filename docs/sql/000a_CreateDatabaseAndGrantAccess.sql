-- ============================================================================
-- Run this FIRST, on csmsvr02, connected to the master database, with an
-- account that has sysadmin or dbcreator + securityadmin rights.
--
-- Fixes: "Cannot open database 'Rittal_Support' requested by the login.
-- Login failed for user 'db_Public_User'." (SQL error 4060)
--
-- That error means the database doesn't exist yet, or exists but the
-- db_Public_User login (the one already used for RittalTLSW) has never been
-- given a mapped user inside it — logins are server-level, but access to
-- each individual database has to be granted separately.
-- ============================================================================

IF DB_ID(N'Rittal_Support') IS NULL
BEGIN
    CREATE DATABASE [Rittal_Support];
END
GO

USE [Rittal_Support];
GO

-- Map the existing server login into this database, if it isn't already.
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'db_Public_User')
BEGIN
    CREATE USER [db_Public_User] FOR LOGIN [db_Public_User];
END
GO

-- db_owner matches what the app needs: it runs EF Core migrations (DDL —
-- create/alter tables and indexes) as well as normal reads/writes. If your
-- DBA prefers a narrower grant instead of db_owner, this combination covers
-- the same ground:
--   ALTER ROLE db_ddladmin ADD MEMBER [db_Public_User];
--   ALTER ROLE db_datareader ADD MEMBER [db_Public_User];
--   ALTER ROLE db_datawriter ADD MEMBER [db_Public_User];
ALTER ROLE db_owner ADD MEMBER [db_Public_User];
GO
