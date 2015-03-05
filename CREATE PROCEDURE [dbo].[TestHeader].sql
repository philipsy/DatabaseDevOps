SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Philip Symons
-- Create date: 2015_0304
-- Description: Prints Header for Test-First development script
-- =============================================
--DROP PROCEDURE [dbo].[TestHeader]
CREATE PROCEDURE [dbo].[TestHeader]
AS
/*
USAGE:
TestHeader
*/
BEGIN
	SET NOCOUNT ON;
	DECLARE @Msg nvarchar(4000)
	DECLARE @crlf nchar(2) = NCHAR(13) + NCHAR(10)

	SET @Msg = 'TEST' 
	+ @crlf + 'Date/Time:' + CAST(SYSDATETIMEOFFSET() as nvarchar(50)) 
	+ @crlf + 'User:' + SUSER_SNAME()
	+ @crlf + 'Server:' + @@SERVERNAME 
	+ @crlf + 'Version:' + @crlf + @@VERSION
	+ @crlf + 'Database:' + DB_NAME()
	+ @crlf + 'Module:' + OBJECT_NAME(@@PROCID)

		
	RAISERROR(@Msg, 10, 1, 1)
	
END
GO
