USE [TESTPIZZAIMPORT]
GO

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES 
               WHERE ROUTINE_NAME = 'ORDERSLOAD'
			   AND ROUTINE_SCHEMA = 'dbo'
			   AND ROUTINE_TYPE = 'PROCEDURE')
			       EXEC ('DROP PROCEDURE dbo.ORDERSLOAD')
GO

CREATE PROCEDURE ORDERSLOAD
AS
SET NOCOUNT ON
BEGIN

DECLARE  @inIDSEED int,
@inORDERID nvarchar(9),
@inCUSTOMERID nvarchar(8),
@inORDERTOTAL MONEY,
@inORDERDATETIME DATETIME,
@inORDERNOTES NVARCHAR(MAX);

SELECT @inIDSEED = CAST(ORDERID as int) FROM ORDERS WHERE RECORDNUMBER = (SELECT MAX(RECORDNUMBER) FROM ORDERS);
SET @inIDSEED = ISNULL(@inIDSEED,0);

DECLARE orders_cursor CURSOR FOR
SELECT 
    b.CUSTOMERID, CONVERT(MONEY, REPLACE(a.ORDERTOTAL,'"','')), 
    CONVERT(DATETIME, SUBSTRING(a.ORDERDATETIME, PATINDEX('%[0-9][0-9][0-9][0-9][_]______%', a.ORDERDATETIME),4)
     + '-' + SUBSTRING(a.ORDERDATETIME, PATINDEX('%[0-9][0-9]______[_]______%', a.ORDERDATETIME),2)
     + '-' + SUBSTRING(a.ORDERDATETIME, PATINDEX('%[0-9][0-9]____[_]______%', a.ORDERDATETIME),2)
     + ' ' + SUBSTRING(a.ORDERDATETIME, PATINDEX('%[0-9][0-9]____"', a.ORDERDATETIME),2)
     + ':' + SUBSTRING(a.ORDERDATETIME, PATINDEX('%[0-9][0-9]__"', a.ORDERDATETIME),2)
     + ':' + SUBSTRING(a.ORDERDATETIME, PATINDEX('%[0-9][0-9]"', a.ORDERDATETIME),2), 120) AS CONVERTEDDATETIME,
	 a.ORDERNOTES 
     FROM
        IMPORT_BULKPIZZADATA a LEFT JOIN CUSTOMERS b ON b.FIRSTNAME = REPLACE(a.FIRSTNAME,'"','')
        AND b.MIDDLEINITIAL = REPLACE(a.MIDDLEINITIAL,'"','') 
		AND b.LASTNAME = REPLACE(a.LASTNAME,'"','')
        AND b.HOMEADDRESS = REPLACE(a.HOMEADDRESS,'"','') 
		AND b.PHONENUMBER = REPLACE(a.PHONENUMBER,'"','');


OPEN orders_cursor;

SET @inIDSEED +=1;
SET @inORDERID = RIGHT('000000000' + CAST(@inIDSEED as nvarchar(9)),9)

FETCH NEXT FROM orders_cursor INTO
    @inCUSTOMERID
   ,@inORDERTOTAL
   ,@inORDERDATETIME
   ,@inORDERNOTES;

WHILE @@FETCH_STATUS = 0
    BEGIN;
        INSERT INTO ORDERS ([ORDERID]
                           ,[CUSTOMERID]
                           ,[ORDERTOTAL]
    		               ,[ORDERDATETIME]
    		               ,[ORDERNOTES])
    	    SELECT @inORDERID AS OID 
    			   ,@inCUSTOMERID AS CID 
    			   ,@inORDERTOTAL AS OTOTAL 
    			   ,@inORDERDATETIME AS ODATETIME
    			   ,@inORDERNOTES
    		       WHERE NOT EXISTS (SELECT 1 FROM ORDERS o WHERE @inCUSTOMERID = o.[CUSTOMERID] 
    				                     AND @inORDERTOTAL = o.[ORDERTOTAL]
    		                             AND @inORDERDATETIME = o.[ORDERDATETIME]);
    
            IF @@ROWCOUNT = 1
    		BEGIN
                SET @inIDSEED +=1;
                SET @inORDERID = RIGHT('000000000' + CAST(@inIDSEED as nvarchar(9)),9)
            END
    
        FETCH NEXT FROM orders_cursor INTO
                             @inCUSTOMERID 
    						,@inORDERTOTAL 
    						,@inORDERDATETIME 
    						,@inORDERNOTES;
    END;

CLOSE orders_cursor;
DEALLOCATE orders_cursor;

END