USE [TESTPIZZAIMPORT]
GO

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES 
               WHERE ROUTINE_NAME = 'CUSTOMERLOAD'
			   AND ROUTINE_SCHEMA = 'dbo'
			   AND ROUTINE_TYPE = 'PROCEDURE')
			       EXEC ('DROP PROCEDURE dbo.CUSTOMERLOAD')
GO

CREATE PROCEDURE CUSTOMERLOAD
AS
SET NOCOUNT ON
BEGIN
DECLARE  @inIDSEED int,
@inCUSTOMERID nvarchar(8),
@inFIRSTNAME nvarchar(100),
@inMIDDLEINITIAL nvarchar(5),
@inLASTNAME nvarchar(100),
@inPHONENUMBER nvarchar(12),
@inHOMEADDRESS nvarchar(200);

SELECT @inIDSEED = CAST(CUSTOMERID as int) FROM CUSTOMERS WHERE RECORDNUMBER = (SELECT MAX(RECORDNUMBER) FROM CUSTOMERS);
SET @inIDSEED = ISNULL(@inIDSEED,0);

DECLARE customer_cursor CURSOR FOR
    SELECT [FIRSTNAME]
          ,[MIDDLEINITIAL]
          ,[LASTNAME]
          ,[PHONENUMBER]
          ,[HOMEADDRESS]
    FROM [dbo].[IMPORT_CUSTOMERDATA];

OPEN customer_cursor;

SET @inIDSEED +=1;
SET @inCUSTOMERID = RIGHT('00000000' + CAST(@inIDSEED as nvarchar(8)),8)

FETCH NEXT FROM customer_cursor INTO
    @inFIRSTNAME
   ,@inMIDDLEINITIAL
   ,@inLASTNAME
   ,@inPHONENUMBER
   ,@inHOMEADDRESS;

WHILE @@FETCH_STATUS = 0
    BEGIN;
        INSERT INTO CUSTOMERS ([CUSTOMERID]
               ,[FIRSTNAME]
               ,[MIDDLEINITIAL]
               ,[LASTNAME]
               ,[PHONENUMBER]
               ,[HOMEADDRESS])
    		       SELECT REPLACE(@inCUSTOMERID,'"','') AS CUST
    			         ,REPLACE(@inFIRSTNAME,'"','') AS FNAME
    			         ,REPLACE(@inMIDDLEINITIAL,'"','') AS MI 
    		             ,REPLACE(@inLASTNAME,'"','') AS LNAME
    		             ,REPLACE(@inPHONENUMBER,'"','') AS PHONE
    		             ,REPLACE(@inHOMEADDRESS,'"','') AS ADDR
    		       WHERE NOT EXISTS (SELECT 1 FROM CUSTOMERS c 
    			                     WHERE REPLACE(@inFIRSTNAME,'"','') = c.[FIRSTNAME] 
    								  AND  REPLACE(@inMIDDLEINITIAL,'"','') = c.[MIDDLEINITIAL]
    		                          AND REPLACE(@inLASTNAME,'"','')  = c.[LASTNAME] 
    								  AND REPLACE(@inPHONENUMBER,'"','') = c.[PHONENUMBER]
    		                          AND REPLACE(@inHOMEADDRESS,'"','') = c.[HOMEADDRESS]);
    
        IF @@ROWCOUNT = 1
    	    BEGIN
    		    SET @inIDSEED +=1;
                SET @inCUSTOMERID = RIGHT('00000000' + CAST(@inIDSEED as nvarchar(8)),8);
    		END
    
    FETCH NEXT FROM customer_cursor INTO
        @inFIRSTNAME
       ,@inMIDDLEINITIAL
       ,@inLASTNAME
       ,@inPHONENUMBER
       ,@inHOMEADDRESS;
    END;

CLOSE customer_cursor;
DEALLOCATE customer_cursor;
END