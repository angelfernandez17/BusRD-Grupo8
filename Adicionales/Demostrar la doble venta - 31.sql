USE BusRD;
GO

SELECT
    BoletoID,
    ViajeID,
    NumeroAsiento,
    ClienteID,
    Estado,
    FechaVenta
FROM dbo.Boletos
WHERE ViajeID = 16433
  AND NumeroAsiento = 3;
GO