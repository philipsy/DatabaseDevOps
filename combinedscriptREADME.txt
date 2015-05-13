This is a Proof of Concept for a Blue/Green deployment sub-system. Scripts are written for Sql Server 2014 Development Edition
Data changes to the live database are "journalled" by triggers into a separate database from which they can be loaded
into the offline database. Combined.sql is composed of twenty individual scripts rolled up into the file
in the order of execution. The security model has been stripped out so you'll need a privileged account to execute it.
DROP statements are not included to avoid name clashes with existing objects. Before running it,
you'll need to create three databases: Test, TestBlue and Journal. If there are already databases on the server 
with these names, you'll need to make some changes to avoid these proof-of-concept objects created in your databases.
Dropping the new databases at the end of the test should undo all changes.

The deployment inserts a few rows into the Test..T1 table. After running it you'll need to run a stored procedure
to copy the rows into the TestBlue database by running the following script: 

-------------------------------------------------------------------------------------------------------------------------------------
USE Test
GO

DECLARE @DateTimeFrom datetimeoffset = (SELECT MIN(DateTimeChange) FROM Journal..JournalDetail)
DECLARE @DateTimeTo datetimeoffset = (SELECT MAX(DateTimeChange) FROM Journal..JournalDetail)

EXEC TestBlue.[test_tables].[uspLoadUpdates]
@i_DateTimeFrom = @DateTimeFrom 
,@i_DateTimeTo = @DateTimeTo 
,@i_Debug= 1
---------------------------------------------------------------------------------------------------------------------

You can check that data in both databases is now identical as follows:

USE Test
GO
SELECT C1, C2, C3 FROM T1
EXCEPT
SELECT C1, C2, C3 FROM TestBlue..T1

SELECT C1, C2, C3 FROM TestBlue..T1
EXCEPT
SELECT C1, C2, C3 FROM T1

