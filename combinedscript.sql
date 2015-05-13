USE Journal
GO

CREATE SCHEMA test_tables

GO
CREATE SCHEMA test_api

GO

USE Test
GO

CREATE SCHEMA test_tables


GO
CREATE SCHEMA test_api

GO


USE TestBlue
GO

CREATE SCHEMA test_tables
GO
CREATE SCHEMA test_api
GO
/********************020 CREATE TABLE [dbo].[Journal].sql********************/
USE [Journal]
GO

/****** Object:  Table [dbo].[Journal]    Script Date: 18/04/2015 16:57:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--DROP TABLE [dbo].[Journal]
CREATE TABLE [dbo].[Journal]
(
	[JournalId] [bigint] NOT NULL,
	[ServerName] [sysname] NULL CONSTRAINT DEF_JNLServerName DEFAULT(@@servername),
	--database schema versions increment independently of application--
	DbVersionNum varchar(14) NOT NULL,
	--collect numerical and language settings for current connection not needed for blue/green deployment but may help with troubleshooting--
	SessionOptions sysname NOT NULL CONSTRAINT DEF_JNLSessionOptions DEFAULT(@@options),
	SessionLanguage sysname NOT NULL CONSTRAINT DEF_JNLSessionLanguage DEFAULT(@@language),
	SessionID int NOT NULL CONSTRAINT DEF_JNLSessionId DEFAULT(@@spid),
	OriginalLogin sysname NOT NULL CONSTRAINT DEF_JNLOriginalLogin DEFAULT(ORIGINAL_LOGIN()),
	SUserName nvarchar(128) NOT NULL CONSTRAINT DEF_JNLUserName DEFAULT(SUSER_NAME()),
	/*
	top-level Transact-Sql statement stored in this column. data changes can be replayed at statement- instead of row- level
	primary keys should not be updated but if it were essential to reconcile physical rows this could probably be used
	*/
	DBCC_InputBuffer nvarchar(4000) NULL,
	--use datetimeoffset to avoid daylight saving time affecting order of rows--
	[DateTimeInsert] [datetimeoffset](7) NOT NULL CONSTRAINT JNLDateTimeInsert DEFAULT(SYSDATETIMEOFFSET()),
	CONSTRAINT [PK_JNL] PRIMARY KEY CLUSTERED 
	(
		[JournalId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO




/****************030 CREATE TABLE [dbo].[JournalDetail].sql****************/
USE Journal
GO


--DROP TABLE [dbo].[JournalDetail]
CREATE TABLE [dbo].[JournalDetail]
(
JournalId bigint NOT NULL
,JournalDetailId bigint NOT NULL
--records name of active code module which will generally be trigger doing INSERT--
,ModuleName sysname NULL CONSTRAINT DEF_JNLDModuleName DEFAULT(OBJECT_NAME(@@PROCID))
--to fully qualify object name join to Journal table and concatenate to server/database name--
,ParentTableSchema sysname NOT NULL
,ParentTable sysname NOT NULL
,DMLAction char(1) NOT NULL CONSTRAINT CHK_JNLDDMLAction CHECK(DmlAction In('I', 'U', 'D'))
,DateTimeChange datetimeoffset NOT NULL CONSTRAINT DEF_JNLDDateTimeChange DEFAULT(sysdatetimeoffset())
,CONSTRAINT FK_JNL_JNLD
 FOREIGN KEY(JournalId)
 REFERENCES dbo.Journal(JournalId)
)



/**************040 CREATE SEQUENCE [dbo].[Journal_Sequence].sql**************/
USE [Journal]
GO

USE [Journal]
GO

/****** Object:  Sequence [dbo].[Journal_Sequence]    Script Date: 20/04/2015 14:31:55 ******/
--DROP SEQUENCE [dbo].[Journal_Sequence] 
CREATE SEQUENCE [dbo].[Journal_Sequence] 
 AS [bigint]
 START WITH 1
 INCREMENT BY 1
 MINVALUE 1
 MAXVALUE 9223372036854775807
 CACHE 
 CYCLE
GO



/**********050 CREATE SEQUENCE [dbo].[JournalDetail_Sequence].sql**********/
USE Journal
go

--DROP SEQUENCE [dbo].[JournalDetail_Sequence]
CREATE SEQUENCE [dbo].[JournalDetail_Sequence] As bigint
START WITH 1
INCREMENT BY 1
MINVALUE 1
CYCLE
/******************060 CREATE TABLE Test.test_tables.T1.sql******************/
USE Test
GO

--DROP TABLE test_tables.T1
CREATE TABLE test_tables.T1
(
C1 int NOT NULL PRIMARY KEY(C1)
,C2 int NULL
,C3 varchar(10) NULL
,DateTimeInserted datetimeoffset DEFAULT(sysdatetimeoffset())
)


--DROP TABLE Journal..T1_Audit
GO
/*******************080 CREATE TABLE Journal.T1_Audit.sql*******************/
USE Test
GO

--DROP TABLE Journal..T1_Audit
CREATE TABLE Journal..T1_Audit
(
C1 int NULL
,C2 int NULL
,C3 varchar(10) NULL
,DateTimeInserted datetimeoffset NOT NULL 
,SPID int NOT NULL DEFAULT(@@SPID)
,JournalId bigint NOT NULL 
,JournalDetailId bigint NOT NULL 
,DMLAction varchar(2) NOT NULL 
--unlike JournalDetail table updates are split into Deleted ('UD') and Inserted ('UI;) which makes replay easier--
 CHECK(DMLAction In('I', 'UI', 'UD', 'D'))
 --datetimeoffset may be identical so this column provides definite ordering--
,DMLOrdering bigint NOT NULL
,DateTimeAudit datetimeoffset NOT NULL DEFAULT(sysdatetimeoffset())
)

GO
/****************100 CREATE TABLE TestBlue.test_tables.T1.sql****************/
USE TestBlue
GO

/*
commented out in case you have a T1 table you intend to keep!
DROP TABLE T1
*/
CREATE TABLE test_tables.T1
(
JournalId bigint NOT NULL
,C1 int NOT NULL PRIMARY KEY(C1)
,C2 int NULL
,C3 varchar(10) NULL
)

GO
/**************************120 CREATE SYNONYMS.sql**************************/
USE Test
go

CREATE SYNONYM T1 FOR test_tables.T1
CREATE SYNONYM T2 FOR test_tables.T2

go

USE TestBlue
go

CREATE SYNONYM T1 FOR test_tables.T1
CREATE SYNONYM T2 FOR test_tables.T2
/**********************130 CREATE USER TableOwner.sql**********************/
USE Journal
go

CREATE USER TableOwner WITHOUT LOGIN

ALTER USER TableOwner
WITH DEFAULT_SCHEMA = test_tables


USE Test
go

CREATE USER TableOwner WITHOUT LOGIN

ALTER USER TableOwner
WITH DEFAULT_SCHEMA = test_tables

USE TestBlue
go

CREATE USER TableOwner WITHOUT LOGIN

ALTER USER TableOwner
WITH DEFAULT_SCHEMA = test_tables

/************140 CREATE FUNCTION [Test].[dbo].[DbVersionNum].sql************/
USE Test
go

--DROP FUNCTION [test_api].[DbVersionNum]
CREATE FUNCTION [test_api].[DbVersionNum]
()
RETURNS varchar(14)
As
/*
USAGE:
SELECT [dbo].[DbVersionNum]()
*/
BEGIN
	RETURN '1.0.0'
END
go

USE TestBlue
go

--DROP FUNCTION [test_api].[DbVersionNum]
CREATE FUNCTION [test_api].[DbVersionNum]
()
RETURNS varchar(14)
As
/*
USAGE:
SELECT [dbo].[DbVersionNum]()
*/
BEGIN
	RETURN '1.0.0'
END

GO
/****************150 CREATE FUNCTION [dbo].[ColumnList].sql****************/
USE TestBlue
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		P. Symons
-- Create date: 9 May 2015
-- Description:	Return comma-delimited column list
-- =============================================
--DROP FUNCTION [dbo].[ColumnList]
CREATE FUNCTION [dbo].[ColumnList]
(
@i_TableName nvarchar(256)
)
RETURNS nvarchar(1000)
AS
/*
USAGE:
SELECT [dbo].[ColumnList]('T1')
SELECT [dbo].[ColumnList]('Test..T1')
SELECT [dbo].[ColumnList]('Test.test_tables.T1')
SELECT [dbo].[ColumnList]('Test..dbo.T1')
TESTING:
SELECT [dbo].[ColumnList]('Test.....dbo.T1')
*/
BEGIN
	DECLARE @TableName sysname = COALESCE(PARSENAME(@i_TableName, 1), @i_TableName)
	
	DECLARE @ColumnList nvarchar(4000) = ''
	SELECT @ColumnList += CASE WHEN @ColumnList <> '' THEN CHAR(13) + CHAR(10) + ',' ELSE '' END + c.name 
	from sys.tables t
	JOIN sys.all_columns c
	ON t."object_id" = c."object_id"
	WHERE t.name = @TableName
	
	RETURN @ColumnList 
	
END
GO


/**********160 CREATE TRIGGER [test_tables].[T1_INSERT_TRIGGER].sql**********/
USE Test
GO

--DROP TRIGGER [test_tables].[T1_INSERT_TRIGGER]
CREATE TRIGGER [test_tables].[T1_INSERT_TRIGGER]
   ON  [test_tables].[T1]
   AFTER INSERT
AS 
BEGIN
	SET NOCOUNT ON;
	--ensure that timestamps are identical in both databases--
	DECLARE @Msg nvarchar(4000)
	DECLARE @VersionNum varchar(14) = test_api.DbVersionNum()
	DECLARE @DateTimeInsert datetimeoffset = sysdatetimeoffset()
	--DECLARE @DateTimeInsert datetimeoffset = (SELECT MAX(DateTimeChange) FROM Inserted HAVING COUNT(DISTINCT DateTimeChange) = 1)
	DECLARE @JournalId bigint = -1
	DECLARE @SavedBufferedCmd nvarchar(4000)
	DECLARE @NotFound int = -1
	DECLARE @UnlikelyNum int = -999
	DECLARE @UnlikelyString varchar(15) = '!€`¬¦{}()[]' + CHAR(9) + CHAR(13) + CHAR(10) + CHAR(8)
	
	--get journalid if available from session context info--
	DECLARE @ContextInfo varbinary(128) = CONTEXT_INFO()
	IF @ContextInfo Is Not Null And @ContextInfo <> 0x0
	BEGIN
		SET @JournalId = CAST(CONTEXT_INFO() as varbinary(8))
	END
	
	--get current top level command--
	DECLARE @DBCCResult As TABLE(EventType nvarchar(30), "Parameters" smallint, EventInfo nvarchar(4000))
	INSERT INTO @DBCCResult EXEC('DBCC INPUTBUFFER(@@SPID) WITH NO_INFOMSGS')
	DECLARE @BufferedCmd nvarchar(4000) = (SELECT MAX(EventInfo) FROM @DBCCResult HAVING COUNT(*) = 1)
	
	--get latest values in journal table--
	DECLARE @SavedJournalId bigint
	SELECT @SavedJournalId = JournalId
	,@SavedBufferedCmd = DBCC_InputBuffer
	FROM
	(
		SELECT *
		,MAX(JournalId) OVER (ORDER BY JournalId ASC ROWS BETWEEN UNBOUNDED PRECEDING And UNBOUNDED FOLLOWING) As Max_JournalId
		FROM Journal..Journal NOCOUNT
	) D1
	WHERE JournalId = Max_JournalId

	IF @JournalId <> COALESCE(@SavedJournalId, @UnlikelyNum) Or @BufferedCmd <> COALESCE(@SavedBufferedCmd, @UnlikelyString)

	--store XACT_ABORT setting--
	DECLARE @XACT_ABORT VARCHAR(3) = CASE WHEN (16384 & @@OPTIONS) = 16384 THEN 'ON' ELSE 'OFF' END
	IF @XACT_ABORT = 'ON' SET XACT_ABORT OFF

	--compare current with saved values to decide whether to create new journal entry--
	IF @JournalId <> COALESCE(@SavedJournalId, @UnlikelyNum) Or @BufferedCmd <> COALESCE(@SavedBufferedCmd, @UnlikelyString)
	BEGIN
		--create new journal entry--
		IF @JournalId = -1
		BEGIN
			SET @JournalId = NEXT VALUE FOR Journal..Journal_Sequence
			DECLARE @JournalIdBinary varbinary(128) = CAST(@JournalId as varbinary(128))
			SET CONTEXT_INFO @JournalIdBinary
		
		END

		INSERT INTO Journal..Journal
		(
		DbVersionNum
		,JournalId
		,DBCC_InputBuffer 
		,DateTimeInsert
		)
		SELECT 
		test_api.DbVersionNum()
		,@JournalId
		,@BufferedCmd 
		,@DateTimeInsert
		--WHERE Not EXISTS(SELECT Null FROM Journal..Journal WHERE JournalId = @JournalId)

	END

	DECLARE @JournalDetailId bigint = NEXT VALUE FOR Journal..JournalDetail_Sequence

	INSERT INTO
	Journal..JournalDetail
	(
	JournalId
	,JournalDetailId
	,ModuleName
	,ParentTableSchema
	,ParentTable
	,DMLAction
	)
	VALUES
	(
	@JournalId 
	,@JournalDetailId 
	,OBJECT_NAME(@@PROCID)
	,'test_tables'
	,'T1'
	,'I'
	)
	--reset to original XACT_ABORT setting--
	IF @XACT_ABORT = 'ON' SET XACT_ABORT ON

	
	INSERT INTO Journal..T1_Audit
	(
	C1
	,C2
	,C3
	,DateTimeInserted
	,JournalId
	,JournalDetailId
	,DMLAction
	,DMLOrdering
	)
	--use SELECT * with derived table to fail if columns mismatched--
	SELECT *
	,@JournalId
	,@JournalDetailId
	,'I' As DMLAction
	,ROW_NUMBER() OVER (ORDER BY GETDATE()) As DMLOrdering
	FROM Inserted
		
END



GO

/**********170 CREATE TRIGGER [test_tables].[T1_UPDATE_TRIGGER].sql**********/
USE Test
GO

--DROP TRIGGER [test_tables].[T1_UPDATE_TRIGGER]
CREATE TRIGGER [test_tables].[T1_UPDATE_TRIGGER]
   ON  [test_tables].[T1]
   AFTER UPDATE
AS 
BEGIN
	SET NOCOUNT ON;
	--ensure that timestamps are identical in both databases--
	DECLARE @Msg nvarchar(4000)
	DECLARE @VersionNum varchar(14) = test_api.DbVersionNum()
	DECLARE @DateTimeInsert datetimeoffset = sysdatetimeoffset()
	--DECLARE @DateTimeInsert datetimeoffset = (SELECT MAX(DateTimeChange) FROM Inserted HAVING COUNT(DISTINCT DateTimeChange) = 1)
	DECLARE @JournalId bigint = -1
	DECLARE @SavedBufferedCmd nvarchar(4000)
	DECLARE @NotFound int = -1
	DECLARE @UnlikelyNum int = -999
	DECLARE @UnlikelyString varchar(15) = '!€`¬¦{}()[]' + CHAR(9) + CHAR(13) + CHAR(10) + CHAR(8)
	
	--get journalid if available from session context info--
	DECLARE @ContextInfo varbinary(128) = CONTEXT_INFO()
	IF @ContextInfo Is Not Null And @ContextInfo <> 0x0
	BEGIN
		SET @JournalId = CAST(CONTEXT_INFO() as varbinary(8))
	END
	
	--get current top level command--
	DECLARE @DBCCResult As TABLE(EventType nvarchar(30), "Parameters" smallint, EventInfo nvarchar(4000))
	INSERT INTO @DBCCResult EXEC('DBCC INPUTBUFFER(@@SPID) WITH NO_INFOMSGS')
	DECLARE @BufferedCmd nvarchar(4000) = (SELECT MAX(EventInfo) FROM @DBCCResult HAVING COUNT(*) = 1)
	
	--get latest values in journal table--
	DECLARE @SavedJournalId bigint
	SELECT @SavedJournalId = JournalId
	,@SavedBufferedCmd = DBCC_InputBuffer
	FROM
	(
		SELECT *
		,MAX(JournalId) OVER (ORDER BY JournalId ASC ROWS BETWEEN UNBOUNDED PRECEDING And UNBOUNDED FOLLOWING) As Max_JournalId
		FROM Journal..Journal NOCOUNT
	) D1
	WHERE JournalId = Max_JournalId

	IF @JournalId <> COALESCE(@SavedJournalId, @UnlikelyNum) Or @BufferedCmd <> COALESCE(@SavedBufferedCmd, @UnlikelyString)

	--store XACT_ABORT setting--
	DECLARE @XACT_ABORT VARCHAR(3) = CASE WHEN (16384 & @@OPTIONS) = 16384 THEN 'ON' ELSE 'OFF' END
	IF @XACT_ABORT = 'ON' SET XACT_ABORT OFF

	--compare current with saved values to decide whether to create new journal entry--
	IF @JournalId <> COALESCE(@SavedJournalId, @UnlikelyNum) Or @BufferedCmd <> COALESCE(@SavedBufferedCmd, @UnlikelyString)
	BEGIN
		--create new journal entry--
		IF @JournalId = -1
		BEGIN
			SET @JournalId = NEXT VALUE FOR Journal..Journal_Sequence
			DECLARE @JournalIdBinary varbinary(128) = CAST(@JournalId as varbinary(128))
			SET CONTEXT_INFO @JournalIdBinary
		
		END

		INSERT INTO Journal..Journal
		(
		DbVersionNum
		,JournalId
		,DBCC_InputBuffer 
		,DateTimeInsert
		)
		SELECT 
		test_api.DbVersionNum()
		,@JournalId
		,@BufferedCmd 
		,@DateTimeInsert
		WHERE Not EXISTS(SELECT Null FROM Journal..Journal WHERE JournalId = @JournalId)

	END

	DECLARE @JournalDetailId bigint = NEXT VALUE FOR Journal..JournalDetail_Sequence

	INSERT INTO
	Journal..JournalDetail
	(
	JournalId
	,JournalDetailId
	,ModuleName
	,ParentTableSchema
	,ParentTable
	,DMLAction
	)
	VALUES
	(
	@JournalId 
	,@JournalDetailId 
	,OBJECT_NAME(@@PROCID)
	,'test_tables'
	,'T1'
	,'U'
	)
	--reset to original XACT_ABORT setting--
	IF @XACT_ABORT = 'ON' SET XACT_ABORT ON

	INSERT INTO Journal..T1_Audit
	(
	C1
	,C2
	,C3
	,DateTimeInserted
	,JournalId
	,JournalDetailId
	,DMLAction
	,DMLOrdering
	)
	--use SELECT * with derived table to fail if columns mismatched--
	SELECT *
	,@JournalId
	,@JournalDetailId
	,'UI' As DMLAction
	,ROW_NUMBER() OVER (ORDER BY GETDATE()) As DMLOrdering
	FROM Inserted

	INSERT INTO Journal..T1_Audit
	(
	C1
	,C2
	,C3
	,DateTimeInserted
	,JournalId
	,JournalDetailId
	,DMLAction
	,DMLOrdering
	)
	--use SELECT * with derived table to fail if columns mismatched--
	SELECT *
	,@JournalId
	,@JournalDetailId
	,'UD' As DMLAction
	,ROW_NUMBER() OVER (ORDER BY GETDATE()) As DMLOrdering
	FROM Deleted

END



GO

/**********180 CREATE TRIGGER [test_tables].[T1_DELETE_TRIGGER].sql**********/
USE Test
GO

--DROP TRIGGER [test_tables].[T1_DELETE_TRIGGER]
CREATE TRIGGER [test_tables].[T1_DELETE_TRIGGER]
   ON  [test_tables].[T1]
   AFTER DELETE
AS 
BEGIN
	SET NOCOUNT ON;
	--ensure that timestamps are identical in both databases--
	DECLARE @Msg nvarchar(4000)
	DECLARE @VersionNum varchar(14) = test_api.DbVersionNum()
	DECLARE @DateTimeInsert datetimeoffset = sysdatetimeoffset()
	DECLARE @JournalId bigint = -1
	DECLARE @SavedBufferedCmd nvarchar(4000)
	DECLARE @NotFound int = -1
	DECLARE @UnlikelyNum int = -999
	DECLARE @UnlikelyString varchar(15) = '!€`¬¦{}()[]' + CHAR(9) + CHAR(13) + CHAR(10) + CHAR(8)
	
	--get journalid if available from session context info--
	DECLARE @ContextInfo varbinary(128) = CONTEXT_INFO()
	IF @ContextInfo Is Not Null And @ContextInfo <> 0x0
	BEGIN
		SET @JournalId = CAST(CONTEXT_INFO() as varbinary(8))
	END
	
	--get current top level command--
	DECLARE @DBCCResult As TABLE(EventType nvarchar(30), "Parameters" smallint, EventInfo nvarchar(4000))
	INSERT INTO @DBCCResult EXEC('DBCC INPUTBUFFER(@@SPID) WITH NO_INFOMSGS')
	DECLARE @BufferedCmd nvarchar(4000) = (SELECT MAX(EventInfo) FROM @DBCCResult HAVING COUNT(*) = 1)
	
	--get latest values in journal table--
	DECLARE @SavedJournalId bigint
	SELECT @SavedJournalId = JournalId
	,@SavedBufferedCmd = DBCC_InputBuffer
	FROM
	(
		SELECT *
		,MAX(JournalId) OVER (ORDER BY JournalId ASC ROWS BETWEEN UNBOUNDED PRECEDING And UNBOUNDED FOLLOWING) As Max_JournalId
		FROM Journal..Journal NOCOUNT
	) D1
	WHERE JournalId = Max_JournalId

	IF @JournalId <> COALESCE(@SavedJournalId, @UnlikelyNum) Or @BufferedCmd <> COALESCE(@SavedBufferedCmd, @UnlikelyString)

	--store XACT_ABORT setting--
	DECLARE @XACT_ABORT VARCHAR(3) = CASE WHEN (16384 & @@OPTIONS) = 16384 THEN 'ON' ELSE 'OFF' END
	IF @XACT_ABORT = 'ON' SET XACT_ABORT OFF

	--compare current with saved values to decide whether to create new journal entry--
	IF @JournalId <> COALESCE(@SavedJournalId, @UnlikelyNum) Or @BufferedCmd <> COALESCE(@SavedBufferedCmd, @UnlikelyString)
	BEGIN
		--create new journal entry--
		IF @JournalId = -1
		BEGIN
			SET @JournalId = NEXT VALUE FOR Journal..Journal_Sequence
			DECLARE @JournalIdBinary varbinary(128) = CAST(@JournalId as varbinary(128))
			SET CONTEXT_INFO @JournalIdBinary
		
		END

		INSERT INTO Journal..Journal
		(
		DbVersionNum
		,JournalId
		,DBCC_InputBuffer 
		,DateTimeInsert
		)
		SELECT 
		test_api.DbVersionNum()
		,@JournalId
		,@BufferedCmd 
		,@DateTimeInsert
		WHERE Not EXISTS(SELECT Null FROM Journal..Journal WHERE JournalId = @JournalId)

	END

	DECLARE @JournalDetailId bigint = NEXT VALUE FOR Journal..JournalDetail_Sequence

	INSERT INTO
	Journal..JournalDetail
	(
	JournalId
	,JournalDetailId
	,ModuleName
	,ParentTableSchema
	,ParentTable
	,DMLAction
	)
	VALUES
	(
	@JournalId 
	,@JournalDetailId 
	,OBJECT_NAME(@@PROCID)
	,'test_tables'
	,'T1'
	,'D'
	)
	--reset to original XACT_ABORT setting--
	IF @XACT_ABORT = 'ON' SET XACT_ABORT ON

	INSERT INTO Journal..T1_Audit
	(
	C1
	,C2
	,C3
	,DateTimeInserted
	,JournalId
	,JournalDetailId
	,DMLAction
	,DMLOrdering
	)
	--use SELECT * with derived table to fail if columns mismatched--
	SELECT *
	,@JournalId
	,@JournalDetailId
	,'D' As DMLAction
	,ROW_NUMBER() OVER (ORDER BY GETDATE()) As DMLOrdering
	FROM Deleted
		
END



GO

/**********190 CREATE PROCEDURE [test_tables].[uspLoadUpdates].sql**********/
USE TestBlue
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		P. Symons
-- Create date: 9 May 2015
-- Description:	Loads local tables from Journal database
-- =============================================
--DROP PROCEDURE [test_tables].[uspLoadUpdates]
CREATE PROCEDURE [test_tables].[uspLoadUpdates]
@i_DateTimeFrom datetimeoffset
,@i_DateTimeTo datetimeoffset
,@i_Debug int = 0
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @Msg nvarchar(4000)
	DECLARE @Sql varchar(4000) = ''	
	DECLARE @JournalId bigint
	DECLARE @JournalDetailId bigint = 0
	DECLARE @ParentTableSchema sysname
	DECLARE @ParentTable sysname
	DECLARE @PKColName sysname
	DECLARE @DMLAction char(1)
	DECLARE @crlf char(2) = CHAR(13) + CHAR(10)
	DECLARE @sq char(1) = CHAR(39)

	WHILE @JournalDetailId Is Not Null
	BEGIN
		--PRINT 'Looping...'
		SELECT @JournalDetailId = MIN(JournalDetailId) 
		FROM Journal..JournalDetail
		WHERE JournalDetailId > @JournalDetailId
		And DateTimeChange Between COALESCE(@i_DateTimeFrom, DateTimeChange) And COALESCE(@i_DateTimeTo, DateTimeChange)
	
		SELECT @JournalId = JournalId
		,@ParentTableSchema = ParentTableSchema
		,@ParentTable = ParentTable
		,@DMLAction = DMLAction
		,@PKColName = 'C1' --TODO: Remove hard-coding
		FROM Journal..JournalDetail
		WHERE JournalDetailId = @JournalDetailId 
		
		IF @i_Debug > 0 PRINT '@DMLAction:' + COALESCE(@DMLAction, '[Null]')
		DECLARE @FQLocalTable varchar(256) = @ParentTableSchema + '.' + @ParentTable
		DECLARE @JournalTable varchar(256) = 'Journal' + '.' + 'dbo' + '.' + @ParentTable + '_Audit'
		IF @DMLAction = 'I'
		BEGIN
			SET @Sql = 'INSERT INTO' + ' ' + @FQLocalTable + @crlf + '(' + @crlf + dbo.ColumnList(@FQLocalTable) + @crlf + ')'
			+ @crlf + 'SELECT' + @crlf + dbo.ColumnList(@ParentTable) 
			+ @crlf + 'FROM' + @crlf + @JournalTable 
			+ @crlf + 'WHERE' + ' ' + 'JournalId=' + CAST(@JournalId as varchar(12)) 
			+ ' ' + 'And' + ' ' + 'JournalDetailId=' + CAST(@JournalDetailId as varchar(12))
			--PRINT @Sql
			EXEC(@Sql)
		END
		ELSE
		IF @DMLAction = 'U'
		BEGIN
			SET @Sql = 'DELETE' + ' ' + @FQLocalTable
			+ @crlf + 'FROM' + ' ' + @FQLocalTable
			+ @crlf + 'JOIN' + ' ' + @JournalTable
			+ @crlf + 'ON' + ' ' + @FQLocalTable + '.' + @PKColName 
			+ '=' + @JournalTable + '.' + @PKColName 
			+ @crlf + 'WHERE' + ' ' + @JournalTable + '.' + 'JournalId=' + CAST(@JournalId as varchar(12)) 
			+ ' ' + 'And' + ' ' + 'JournalDetailId=' + CAST(@JournalDetailId as varchar(12))
			+ ' ' + 'And' + ' ' + 'DMLAction=' + @sq + 'UD' + @sq
			IF @i_Debug > 0 PRINT @Sql
			EXEC(@Sql)

			SET @Sql = 'INSERT INTO' + ' ' + @ParentTableSchema + '.' + @ParentTable + @crlf + '(' + @crlf + dbo.ColumnList(@ParentTable) + @crlf + ')'
			+ @crlf + 'SELECT' + @crlf + dbo.ColumnList(@ParentTable) 
			+ @crlf + 'FROM' + @crlf + @JournalTable
			+ @crlf + 'WHERE' + ' ' + 'JournalId=' + CAST(@JournalId as varchar(12)) 
			+ ' ' + 'And' + ' ' + 'JournalDetailId=' + CAST(@JournalDetailId as varchar(12))
			+ ' ' + 'And' + ' ' + 'DMLAction=' + @sq + 'UI' + @sq
			
			IF @i_Debug > 0 PRINT @Sql
			EXEC(@Sql)

		END
		ELSE
		IF @DMLAction = 'D'
		BEGIN
			SET @Sql = 'DELETE' + ' ' + @FQLocalTable
			+ @crlf + 'FROM' + ' ' + @FQLocalTable
			+ @crlf + 'JOIN' + ' ' + @JournalTable
			+ @crlf + 'ON' + ' ' + @FQLocalTable + '.' + @PKColName 
			+ '=' + @JournalTable + '.' + @PKColName 
			+ @crlf + 'WHERE' + ' ' + @JournalTable + '.' + 'JournalId=' + CAST(@JournalId as varchar(12)) 
			+ ' ' + 'And' + ' ' + 'JournalDetailId=' + CAST(@JournalDetailId as varchar(12))
			+ ' ' + 'And' + ' ' + 'DMLAction=' + @sq + 'D' + @sq

			IF @i_Debug > 0 PRINT @Sql
			EXEC(@Sql)

		END
		ELSE
		BEGIN
			SET @Msg = '@DMLAction' + ' ' + @sq + COALESCE(@DMLAction, '[Null]') + @sq + ' ' + 'not recognised.'
			;THROW 50000, @Msg, 1
		END

	END
    
END

GO

/**********************200 Populate From DW Tables.sql**********************/
USE Test
GO

--SELECT * FROM T1

INSERT INTO Test..T1
(
C1
,C2
,C3
)
SELECT *
FROM
(
SELECT
ROW_NUMBER() OVER (ORDER BY GETDATE()) As C1
,ROW_NUMBER() OVER (ORDER BY GETDATE()) As C2
,ROW_NUMBER() OVER (ORDER BY GETDATE()) As C3
FROM sys.all_objects
) D1
WHERE C1 Between 1 And 399

/*
SELECT * FROM Test..T1
SELECT DISTINCT DateTimeInserted, DateTimeAudit, DMLAction FROM Journal..T1_Audit
*/

WAITFOR DELAY '00:00:02'

UPDATE Test..T1 SET C2 = 1000 FROM T1 WHERE C1 Between 200 And 399

/*
SELECT * FROM Test..T1
SELECT DISTINCT DateTimeAudit, DateTimeAudit, DMLAction FROM Journal..T1_Audit
*/

WAITFOR DELAY '00:00:02'

UPDATE Test..T1 SET C2 = 2000 FROM T1 WHERE C1 Between 300 And 399

/*
SELECT * FROM Test..T1
SELECT DISTINCT DateTimeInserted, DateTimeAudit, DMLAction FROM Journal..T1_Audit
*/

WAITFOR DELAY '00:00:02'

DELETE Test..T1 WHERE C1 = 399

/*
SELECT * FROM Test..T1
SELECT DISTINCT DateTimeInserted, DateTimeAudit, DMLAction FROM Journal..T1_Audit
*/







