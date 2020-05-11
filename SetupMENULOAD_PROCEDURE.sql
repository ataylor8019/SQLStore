USE [TESTPIZZAIMPORT]
GO

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES 
               WHERE ROUTINE_NAME = 'MENULOAD'
			   AND ROUTINE_SCHEMA = 'dbo'
			   AND ROUTINE_TYPE = 'PROCEDURE')
			       EXEC ('DROP PROCEDURE dbo.MENULOAD')
GO

CREATE PROCEDURE MENULOAD
AS
SET NOCOUNT ON
BEGIN
DECLARE  @inIDSEED int,
@inITEMID nvarchar(5),
@inITEMNAME nvarchar(100),
@inITEMUNITPRICE nvarchar(10);

SELECT @inIDSEED = CAST(ITEMID as int) FROM MENU WHERE RECORDNUMBER = (SELECT MAX(RECORDNUMBER) FROM MENU);
SET @inIDSEED = ISNULL(@inIDSEED,0);

DECLARE menu_cursor CURSOR FOR
    SELECT [ITEMNAME]
          ,[ITEMUNITPRICE]
    FROM [dbo].[IMPORT_MENUDATA];

OPEN menu_cursor;

SET @inIDSEED +=1;
SET @inITEMID = RIGHT('00000' + CAST(@inIDSEED as nvarchar(5)),5)

FETCH NEXT FROM menu_cursor INTO
    @inITEMNAME
   ,@inITEMUNITPRICE;

WHILE @@FETCH_STATUS = 0
    BEGIN;
        INSERT INTO MENU ([ITEMID]
                         ,[ITEMNAME]
                         ,[ITEMUNITPRICE])
    		SELECT @inITEMID AS MENUID
			      ,REPLACE(@inITEMNAME,'"','') AS INAME
				  ,CONVERT(money,REPLACE(@inITEMUNITPRICE,'"','')) AS UNITPRICE
    		WHERE NOT EXISTS (SELECT 1 FROM MENU m WHERE REPLACE(@inITEMNAME,'"','') = REPLACE(m.[ITEMNAME],'"','') 
			                                         AND CONVERT(money,REPLACE(@inITEMUNITPRICE,'"','')) = m.[ITEMUNITPRICE]);
    
    IF @@ROWCOUNT = 1
        BEGIN
            SET @inIDSEED +=1;
            SET @inITEMID = RIGHT('00000' + CAST(@inIDSEED as nvarchar(5)),5)
        END
    
    FETCH NEXT FROM menu_cursor INTO
        @inITEMNAME
	   ,@inITEMUNITPRICE;
    END;

CLOSE menu_cursor;
DEALLOCATE menu_cursor;
END