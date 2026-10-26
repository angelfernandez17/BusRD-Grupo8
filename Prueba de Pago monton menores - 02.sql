
USE BusRD;
GO

SELECT
    b.BoletoID,
    b.Precio AS PrecioBoleto,
    p.Monto AS MontoPagado,
    p.Metodo
FROM dbo.Boletos AS b
INNER JOIN dbo.Pagos AS p
    ON p.BoletoID = b.BoletoID
ORDER BY b.BoletoID DESC;
GO
