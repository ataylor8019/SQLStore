USE [TestPizzaImport]
GO

MERGE ORDEREDITEMS x
    USING (SELECT DISTINCT c.[ORDERID], b.[ITEMID], REPLACE(a.[ITEMLINEITEMNUMBER],'"','') AS LINEITEMNUMBER, 
    CONVERT(NUMERIC(5,0), REPLACE(a.[ITEMQUANTITY],'"','')) AS IQUANTITY, 
    CONVERT(MONEY,REPLACE(a.ITEMPRICEXQUANTITY,'"','')) AS UNITPRICEXQUANTITY
    FROM IMPORT_BULKPIZZADATA a LEFT JOIN MENU b ON REPLACE(a.ITEMNAME,'"','') = b.ITEMNAME AND CONVERT(MONEY,REPLACE(a.ITEMUNITPRICE,'"','')) = b.ITEMUNITPRICE
    LEFT JOIN ORDERS c ON CONVERT(DATETIME, SUBSTRING(a.ORDERDATETIME, PATINDEX('%[0-9][0-9][0-9][0-9][_]______%', a.ORDERDATETIME),4)
     + '-' + SUBSTRING(a.ORDERDATETIME, PATINDEX('%[0-9][0-9]______[_]______%', a.ORDERDATETIME),2)
     + '-' + SUBSTRING(a.ORDERDATETIME, PATINDEX('%[0-9][0-9]____[_]______%', a.ORDERDATETIME),2)
     + ' ' + SUBSTRING(a.ORDERDATETIME, PATINDEX('%[0-9][0-9]____"', a.ORDERDATETIME),2)
     + ':' + SUBSTRING(a.ORDERDATETIME, PATINDEX('%[0-9][0-9]__"', a.ORDERDATETIME),2)
     + ':' + SUBSTRING(a.ORDERDATETIME, PATINDEX('%[0-9][0-9]"', a.ORDERDATETIME),2), 120) = c.[ORDERDATETIME]) y 
    ON x.ORDERID = y.ORDERID AND x.ITEMID = y.ITEMID AND x.ITEMLINEITEMNUMBER = y.LINEITEMNUMBER

WHEN NOT MATCHED BY TARGET THEN
    INSERT ([ORDERID], [ITEMID], [ITEMLINEITEMNUMBER], [ITEMQUANTITY], [ITEMPRICEXQUANTITY])
    VALUES (y.[ORDERID], y.[ITEMID], y.[LINEITEMNUMBER], y.[IQUANTITY], y.[UNITPRICEXQUANTITY]);