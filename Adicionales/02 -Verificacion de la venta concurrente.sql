USE BusRD;
GO

SELECT
    BoletoID,
    ViajeID,
    NumeroAsiento,
    ClienteID,
    Estado
FROM dbo.Boletos
WHERE ViajeID = 16433
  AND NumeroAsiento IN (3, 4, 5)
ORDER BY NumeroAsiento, BoletoID;