
--Tables with row count and schema name
SELECT 
	TableName = t.NAME 
	, SchemaName = s.name
	, p.[Rows]
	, t.create_date 
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN
    sys.schemas s on s.schema_id = t.schema_id
WHERE 
    t.NAME NOT LIKE 'dt%' AND
    i.OBJECT_ID > 255 AND   
    i.index_id <= 1  
GROUP BY 
    t.NAME, i.object_id, i.index_id, i.name,s.name, p.[Rows], t.create_date 
ORDER BY 
    p.[Rows] desc


--System details
SELECT 
SERVERPROPERTY('MachineName') as Host,
SERVERPROPERTY('InstanceName') as Instance,
SERVERPROPERTY('Edition') as Edition, /*shows 32 bit or 64 bit*/
SERVERPROPERTY('ProductLevel') as ProductLevel, /* RTM or SP1 etc*/
Case SERVERPROPERTY('IsClustered') when 1 then 'CLUSTERED' else
'STANDALONE' end as ServerType,
@@VERSION as VersionNumber 

--Databases with recoery model
SELECT name,compatibility_level,recovery_model_desc,state_desc  FROM sys.databases 


--Running tasks and first part of text
SELECT
      p.spid   
	, nt_domain = ltrim(rtrim(left( p.nt_domain,15)))
	, nt_username= left( p.nt_username,15),loginame= left(p.loginame,20)
	, HostName = left(p.hostname,20)  
	, Program_Name = case when [Program_Name] = 'Microsoft SQL Server Management Studio - Query' then 'SSMS' else ltrim(rtrim( program_name)) end  
	, DBName = d.name
	, p.Cpu
	, p.Physical_io  
	, TEXT = left(text, 500)     
	, p.status 
FROM  sysprocesses p  
INNER JOIN sys.sysdatabases d on d.dbid = p.dbid 
	CROSS APPLY sys.dm_exec_sql_text( p.sql_handle)  
WHERE 1=1 
ORDER BY p.cpu DESC


--Search all stored procs for text 
SELECT DISTINCT o.name  ,c.TEXT   
FROM syscomments c    
INNER JOIN sysobjects o ON c.id=o.id    
WHERE c.TEXT LIKE '%wordtofind%' AND o.xtype='P'  


--Tracks connections made to databases over time.   Schedule this job to run every hour or as needed.
CREATE PROCEDURE usp_ConnectionsCount
AS

BEGIN
	SET NOCOUNT ON;
	INSERT INTO Connections 
		SELECT @@ServerName AS server
		,NAME AS dbname
		,COUNT(STATUS) AS number_of_connections
		,GETDATE() AS timestamp
	FROM sys.databases sd
		LEFT JOIN master.dbo.sysprocesses sp ON sd.database_id = sp.dbid
		WHERE database_id NOT BETWEEN 1 AND 4
	GROUP BY NAME
END






 