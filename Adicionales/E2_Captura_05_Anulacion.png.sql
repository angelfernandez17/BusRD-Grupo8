USE BusRD;
GO

SELECT
    b.BoletoID,
    b.NumeroAsiento,
    b.Estado,
    p.Monto,
    p.Metodo,
    p.FechaPago
FROM dbo.Boletos AS b
INNER JOIN dbo.Pagos AS p
    ON b.BoletoID = p.BoletoID
WHERE b.BoletoID = 5
ORDER BY p.FechaPago;