
USE BusRD;
GO

DECLARE @NuevoBoletoID INT;

EXEC dbo.sp_VenderBoleto
    @ViajeID = 16433,
    @NumeroAsiento = 5,
    @ClienteID = 1,
    @Canal = 'Web',
    @Metodo = 'Efectivo',
    @BoletoID = @NuevoBoletoID OUTPUT,
    @SimularDemora = 1;
GO
