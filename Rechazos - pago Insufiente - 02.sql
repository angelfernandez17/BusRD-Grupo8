
DECLARE @PrecioBoleto DECIMAL(10,2) = 350.00;
DECLARE @MontoPagado DECIMAL(10,2) = 200.00;

IF @MontoPagado < @PrecioBoleto
BEGIN
    PRINT 'ERROR: Pago insuficiente.';
    PRINT 'Precio del boleto: RD$350.00';
    PRINT 'Monto recibido: RD$200.00';
    PRINT 'La compra debe ser rechazada.';
END
ELSE
BEGIN
    PRINT 'Pago suficiente.';
END;
GO
