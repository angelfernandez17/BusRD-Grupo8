USE BusRD;
GO

SELECT BoletoID, ViajeID, NumeroAsiento, Estado
FROM dbo.Boletos
WHERE ViajeID = 16433
  AND NumeroAsiento = 4
  AND Estado = 'Activo';
GO