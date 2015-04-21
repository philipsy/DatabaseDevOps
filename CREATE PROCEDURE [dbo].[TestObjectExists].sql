USE [DBA]
GO

/****** Object:  StoredProcedure [dbo].[TestObjectExists]    Script Date: 04/04/2015 15:57:29 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Philip Symons
-- Create date: 4 Apr 2015
-- Description:	Tests existence of objects in database
-- =============================================

--DROP PROCEDURE [dbo].[TestObjectExists]
CREATE PROCEDURE [dbo].[TestObjectExists]
--ALTER PROCEDURE [Test_Harn].[spObjectExists]
@i_ObjectType sysname
,@i_ObjectName sysname = Null
,@i_ParentSchemaName sysname = Null --not needed if testing schema's existence
,@i_DbName sysname = Null
,@i_Debug int = 0
AS
/*
USAGE:
TestObjectExists 'DATABASE', '{Databae Name}',Null,Null,1
TestObjectExists 'SCHEMA', 'dbo'
TestObjectExists 'SCHEMA', 'dbo', Null, 'msdb'
TestObjectExists 'VIEW', 'all_objects', 'sys'
TestObjectExists 'USER_TABLE', 'backupset', 'dbo', 'msdb'
TestObjectExists 'DATABASE_ROLE', '{Role Name}', Null, 'Test'
TestObjectExists 'USER_DEFINED_TABLE_TYPE', '{User Defined Table Type Name', Null, 'msdb'
TestObjectExists 'SEQUENCE', '{Sequence Name}', Null, 'msdb'
TestObjectExists 'USER', '{User Name}', Null, 'DBA'
*/

/*
TESTING:
--bad object type name
TestObjectExists 'BAD OBJECT TYPE', 'all_objects', 'sys'
TestObjectExists 'BAD OBJECT TYPE', 'all_objects', 'sys', msdb
--bad schema name--
TestObjectExists 'VIEW', 'all_objects', 'BAD SCHEMA NAME'
TestObjectExists 'VIEW', 'all_objects', 'BAD SCHEMA NAME', msdb
--bad object name--
TestObjectExists 'VIEW', 'BAD OBJECT NAME', 'sys'
TestObjectExists 'USER_DEFINED_TABLE_TYPE', '{User Defined Table Type Name', Null, msdb
TestObjectExists 'SYNONYM', 'NON_EXISTENT_SYNONYM', Null, 'msdb'
TestObjectExists 'USER_DEFINED_TABLE_TYPE', 'BAD_TABLE_TYPE_NAME', 'dbo'
--object in different schema
TestObjectExists 'VIEW', 'all_objects', 'dbo'
--incompatible parameters--
TestObjectExists 'SCHEMA', 'dbo', 'dbo', 'msdb'
TestObjectExists 'ROLE', '{Role Name}', Null, '{Database Name}'
*/
BEGIN
	SET NOCOUNT ON;
	DECLARE @Msg varchar(4000)
	DECLARE @Sql nvarchar(4000)
	DECLARE @crlf char(2) = CHAR(13) + CHAR(10)
	DECLARE @dq char(1) = CHAR(34)
	DECLARE @sq char(1) = CHAR(39)
	
	SET @i_ObjectType = LTRIM(RTRIM(@i_ObjectType))

	--validate inputs-- 
	IF @i_ObjectName Is Null
	BEGIN
		SET @Msg = '@i_ObjectName must not be Null.'
		RAISERROR(@Msg, 16, 1, 1)
		RETURN 1
	END

	IF @i_ObjectType = 'USER' And @i_ParentSchemaName Is Not Null
	BEGIN
		SET @Msg = 'If @i_ObjectType is "USER" the @i_ParentSchemaName argument must be Null.'
		RAISERROR(@Msg, 16, 1, 1)
		RETURN 1
	END
	ELSE
		IF @i_ObjectType = 'SCHEMA' And @i_ParentSchemaName Is Not Null
	BEGIN
		SET @Msg = 'If @i_ObjectType is "SCHEMA" the @i_ParentSchemaName argument must be Null.'
		RAISERROR(@Msg, 16, 1, 1)
		RETURN 1
	END
	ELSE
	BEGIN
		--help out user by regularising object type names--
		IF @i_ObjectType = 'TABLE' SET @i_ObjectType = 'USER_TABLE'
		IF @i_ObjectType = 'SYNONYM' SET @i_ObjectType = 'SYNONYM_OBJECT'
		IF @i_ObjectType = 'SEQUENCE' SET @i_ObjectType = 'SEQUENCE_OBJECT'
		IF @i_ObjectType = 'TRIGGER' SET @i_ObjectType = 'SQL_TRIGGER'
		IF @i_ObjectType = 'PROCEDURE' SET @i_ObjectType = 'SQL_STORED_PROCEDURE'
		IF @i_ObjectType = 'STORED PROCEDURE' SET @i_ObjectType = 'SQL_STORED_PROCEDURE'

		IF @i_ObjectType = 'ROLE'
		BEGIN
			SET @Msg = 'Object type must be' + ' ' + QUOTENAME('DATABASE_ROLE', CHAR(39))
			RAISERROR(@Msg, 16, 1, 1)
			RETURN 1
		END


	END

	--default any Null parameters--
	SET @i_ParentSchemaName = COALESCE(@i_ParentSchemaName, 'dbo')
	IF @i_ObjectType <> 'DATABASE'
	BEGIN
		SET @i_DbName = COALESCE(@i_DbName, DB_NAME())
	END
	ELSE
	BEGIN
		SET @i_DbName = @i_ObjectName
	END
	
	/*
	Using dynamic Sql below to query other databases on server: before concatenating parameters with sql
	check that database and schema parameters match server object names
	*/
	--check existence of database--
	SET @Sql = N'SELECT name FROM sys.databases';
	IF @i_Debug = 1 PRINT @Sql

	CREATE TABLE #Database(name sysname)
	INSERT INTO #Database EXEC sp_executesql @Sql
	
	DECLARE @DbNameCur sysname = ''
	DECLARE @DbNameFound char = 'N'
	WHILE @DbNameCur Is Not Null
	BEGIN
		SELECT @DbNameCur = MIN(d.name) FROM #Database d WHERE d.name > @DbNameCur 
		IF @i_Debug > 0 
			PRINT '@DbNameCur:' + @DbNameCur + ' ' + '@i_DbName:' + @i_DbName

		IF @DbNameCur = @i_DbName
		BEGIN
			IF @i_ObjectType <> 'DATABASE'
			BEGIN 
				SET @DbNameFound = 'Y'
				BREAK

			END
			ELSE
			BEGIN
				--we only wanted to check database exists so exit proc--
				SET @Msg = @i_ObjectType + ' ' + QUOTENAME(@i_ObjectName, @dq) + ' ' + 'found.'
				RAISERROR(@Msg, 10, 1, 1)
				RETURN 0	

			END
		END

	END
	
	IF @DbNameFound = 'N'
	BEGIN
		SET @Msg = 'Database' + ' ' + QUOTENAME(@i_DbName, @dq) + ' ' + 'not found'
		RAISERROR(@Msg, 16, 1, 1)
		RETURN 1
	END
	
	--check existence of schemas within chosen database--
	SET @Sql = N'SELECT s.name FROM' + ' ' + QUOTENAME(@i_DbName) + '.' + 'sys.schemas s'
	IF @i_Debug = 1	PRINT @Sql

	CREATE TABLE #Schema(name sysname)
	INSERT INTO #Schema EXEC sp_executesql @Sql
	
	DECLARE @SchemaNameCur sysname = ''
	DECLARE @SchemaNameFound char = 'N'
	WHILE @SchemaNameCur Is Not Null
	BEGIN
		SELECT @SchemaNameCur = MIN(s.name) FROM #Schema s WHERE s.name > @SchemaNameCur
		IF @SchemaNameCur = @i_ParentSchemaName
		BEGIN
			IF @i_ObjectType <> 'SCHEMA'
			BEGIN 
				SET @SchemaNameFound = 'Y'
				BREAK

			END
			ELSE
			BEGIN
				SET @Msg = 	@i_ObjectType + ' ' + QUOTENAME(@i_ObjectName, @dq) + ' ' + 'found in' + ' ' + @i_DbName + ' ' + 'database' + '.'
				RAISERROR(@Msg, 10, 1, 1)
				RETURN 0
			END
		
		END

	END
			
	IF @SchemaNameFound = 'N'
	BEGIN
		SET @Msg = 'Schema' +  ' ' + @i_ParentSchemaName + ' ' + 'not found' + ' ' + 'in' + ' ' + @i_DbName + ' ' + 'database' + '.'
		RAISERROR(@Msg, 16, 1, 1)
		RETURN 1
	END
	
	--check existence of object type_desc--
	SET @Sql = N'SELECT DISTINCT type_desc FROM' + ' ' + QUOTENAME(@i_DbName) + '.' + 'sys.all_objects #o'
	+ @crlf + 'UNION ALL' + @crlf + 'SELECT' + ' ' + QUOTENAME('USER_DEFINED_TABLE_TYPE', @sq)
	+ @crlf + 'UNION ALL' + @crlf + 'SELECT' + ' ' + QUOTENAME('DATABASE_ROLE', @sq)
	+ @crlf + 'UNION ALL' + @crlf + 'SELECT' + ' ' + QUOTENAME('SYNONYM', @sq)
	+ @crlf + 'UNION ALL' + @crlf + 'SELECT' + ' ' + QUOTENAME('SQL_TRIGGER', @sq)
	+ @crlf + 'UNION ALL' + @crlf + 'SELECT' + ' ' + QUOTENAME('USER', @sq)
	IF @i_Debug = 1	PRINT @Sql

	CREATE TABLE #distinct_type_descs(type_desc nvarchar(60) NOT NULL)
	INSERT INTO #distinct_type_descs EXEC sp_executesql @Sql

	DECLARE @TypeDescFound char = 'N'
	IF @i_ObjectType <> 'FUNCTION'
	BEGIN
		DECLARE @TypeDescCur sysname = ''
		WHILE @TypeDescCur Is Not Null
		BEGIN
			SELECT @TypeDescCur = MIN(type_desc) FROM #distinct_type_descs WHERE type_desc > @TypeDescCur
			IF @TypeDescCur = @i_ObjectType
			BEGIN
				SET @TypeDescFound = 'Y'
				BREAK
	
			END

		END
	END
	ELSE
	BEGIN
		SET @TypeDescFound = 'Y'
	END

	IF @TypeDescFound = 'N'
	BEGIN
		SET @Msg = 'Object of type' +  ' ' + @i_ObjectType + ' ' + 'not found' + ' ' + 'in' + ' ' + @i_DbName + ' ' + 'database' + '.'
		RAISERROR(@Msg, 16, 1, 1)
		RETURN 1
	END
	
	--test object types which aren't found in usual tables--
	IF @i_ObjectType = 'DATABASE_ROLE'
	BEGIN
		CREATE TABLE #database_principals(name sysname NOT NULL)
		SET @Sql = 'SELECT name FROM' +  ' ' + QUOTENAME(@i_DbName) + '.' + 'sys.database_principals dp WHERE dp.type_desc = ''DATABASE_ROLE'''
		IF @i_Debug = 1	PRINT @Sql
		
		INSERT INTO #database_principals EXEC sp_executesql @Sql
		
		IF NOT EXISTS(SELECT Null FROM #database_principals WHERE name = @i_ObjectName)
		BEGIN
			SET @Msg = 	@i_ObjectType + ' ' + QUOTENAME(@i_ObjectName, @dq) + ' ' + 'not found in' + ' ' + @i_DbName + ' ' + 'sys.database_principals.'
			RAISERROR(@Msg, 16, 1, 1)
			RETURN 1
		END
		ELSE
		BEGIN
			SET @Msg = 	@i_ObjectType + ' ' + QUOTENAME(@i_ObjectName, @dq) + ' ' + 'found in' + ' ' + @i_DbName + ' ' + 'database' + '.'
			RAISERROR(@Msg, 10, 1, 1)
			RETURN 0
		END
		
	END
	
	IF @i_ObjectType = 'USER'
	BEGIN
		CREATE TABLE #users(name sysname NOT NULL)
		SET @Sql = 'SELECT name FROM' +  ' ' + QUOTENAME(@i_DbName) + '.' + 'sys.sysusers u'
		IF @i_Debug = 1	PRINT @Sql
		
		INSERT INTO #users EXEC sp_executesql @Sql
		
		IF NOT EXISTS(SELECT Null FROM #users WHERE name = @i_ObjectName)
		BEGIN
			SET @Msg = 	@i_ObjectType + ' ' + QUOTENAME(@i_ObjectName, @dq) + ' ' + 'not found in' + ' ' + @i_DbName + ' ' + 'sys.sysusers.'
			RAISERROR(@Msg, 16, 1, 1)
			RETURN 1
		END
		ELSE
		BEGIN
			SET @Msg = 	@i_ObjectType + ' ' + QUOTENAME(@i_ObjectName, @dq) + ' ' + 'found in' + ' ' + @i_DbName + ' ' + 'database' + '.'
			RAISERROR(@Msg, 10, 1, 1)
			RETURN 0
		END

	END

	--test standard objects--
	CREATE TABLE #all_objects("schema_name" sysname NOT NULL, name sysname NOT NULL, type_desc nvarchar(60) NOT NULL)
	SET @Sql = N'SELECT s.name As "schema_name", o.name, o.type_desc FROM'
	+ ' ' + QUOTENAME(@i_DbName) + '.' + 'sys.schemas s'
	+ ' ' + 'JOIN' + ' ' + QUOTENAME(@i_DbName) + '.' + 'sys.all_objects o'
	+ ' ' + 'ON s.schema_id = o.schema_id' 
	+ ' ' + 'WHERE s.name =' + QUOTENAME(@i_ParentSchemaName, @sq)
	IF @i_Debug = 1	PRINT @Sql
	
	INSERT INTO #all_objects EXEC sp_executesql @Sql
		
	CREATE TABLE #table_types("schema_name" sysname NOT NULL, name sysname NOT NULL)
	IF @i_ObjectType = 'USER_DEFINED_TABLE_TYPE'
	BEGIN
		SET @Sql = N'SELECT s.name As "schema_name", tt.name FROM'
		+ ' ' + QUOTENAME(@i_DbName) + '.' + 'sys.schemas s'
		+ ' ' + 'JOIN' + ' ' + QUOTENAME(@i_DbName) + '.' + 'sys.table_types tt'
		+ ' ' + 'ON s.schema_id = tt.schema_id'
		IF @i_Debug = 1	PRINT @Sql

		INSERT INTO #table_types EXEC sp_executesql @Sql

	END

	CREATE TABLE #synonyms("schema_name" sysname NOT NULL, name sysname NOT NULL)
	IF @i_ObjectType = 'SYNONYM'
	BEGIN
		SET @Sql = N'SELECT s.name As "schema_name", sy.name FROM'
		+ ' ' + QUOTENAME(@i_DbName) + '.' + 'sys.schemas s'
		+ ' ' + 'JOIN' + ' ' + QUOTENAME(@i_DbName) + '.' + 'sys.synonyms sy'
		+ ' ' + 'ON s.schema_id = sy.schema_id'
		IF @i_Debug = 1	PRINT @Sql

		INSERT INTO #synonyms EXEC sp_executesql @Sql

	END

	IF NOT EXISTS	(
					SELECT Null
					FROM #all_objects #o
					WHERE #o.type_desc = @i_ObjectType 
					And #o.name = @i_ObjectName
					Or 
					(
					#o.name = @i_ObjectName
					And #o.type_desc In (
											'SQL_TABLE_VALUED_FUNCTION'
											,'AGGREGATE_FUNCTION'
											,'SQL_INLINE_TABLE_VALUED_FUNCTION'
											,'CLR_SCALAR_FUNCTION'
											,'SQL_SCALAR_FUNCTION'
											)
					)
					UNION ALL
					SELECT Null
					FROM #table_types #tt
					WHERE @i_ObjectType = 'USER_DEFINED_TABLE_TYPE'
					And #tt."schema_name" = @i_ParentSchemaName
					And #tt.name = @i_ObjectName
					UNION ALL
					SELECT Null
					FROM #synonyms #s
					WHERE @i_ObjectType = 'SYNONYM'
					And #s."schema_name" = @i_ParentSchemaName
					And #s.name = @i_ObjectName
					)
	BEGIN
		--see if object exists in different schema
		IF EXISTS	(
					SELECT Null
					FROM sys.all_objects o 
					WHERE o.type_desc = @i_ObjectType 
					And o.schema_id <> SCHEMA_ID(@i_ParentSchemaName)
					And o.name = @i_ObjectName
					UNION ALL
					SELECT Null
					FROM #table_types #tt
					WHERE @i_ObjectType = 'USER_DEFINED_TABLE_TYPE'
					And #tt."schema_name" <> @i_ParentSchemaName
					And #tt.name = @i_ObjectName
					UNION ALL
					SELECT Null
					FROM #synonyms #s
					WHERE @i_ObjectType = 'SYNONYM'
					And #s."schema_name" <> @i_ParentSchemaName
					And #s.name = @i_ObjectName
					)
		BEGIN
			SET @Msg = 	@i_ObjectType + ' ' + QUOTENAME(@i_ObjectName, @dq) + ' ' + 'in different schema/s of the' + ' ' + @i_DbName + ' ' + 'database to the one specified in "@i_ParentSchemaName"'
			RAISERROR(@Msg, 16, 1, 1)
		END
		ELSE
		BEGIN
			SET @Msg = 	@i_ObjectType + ' ' + QUOTENAME(@i_ObjectName, @dq) + ' ' + 'not found in' + ' ' + @i_DbName + '.'
			RAISERROR(@Msg, 16, 1, 1)
		END
	END
	ELSE
	BEGIN
		SET @Msg = 	@i_ObjectType + ' ' + QUOTENAME(@i_ObjectName, @dq) + ' ' + 'found in' + ' ' + @i_DbName + ' ' + 'database' + '.'
		RAISERROR(@Msg, 10, 1, 1)
			
	END


END


GO


