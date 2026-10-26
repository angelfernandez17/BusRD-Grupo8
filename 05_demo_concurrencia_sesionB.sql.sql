
USE BusRD;
GO

DECLARE @BoletoID INT;

EXEC dbo.sp_VenderBoleto
    @ViajeID = 16433,
    @NumeroAsiento = 6,
    @ClienteID = 1,
    @Canal = 'Web',
    @Metodo = 'Efectivo',
    @BoletoID = @BoletoID OUTPUT,
    @SimularDemora = 0;

SELECT @BoletoID AS BoletoID_SesionB;
GO
