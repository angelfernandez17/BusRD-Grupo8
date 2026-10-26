/*
  E2 - Anulación transaccional de boleto
  Grupo: 8
*/
USE BusRD;
GO

CREATE OR ALTER PROCEDURE dbo.sp_AnularBoleto
    @BoletoID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Estado VARCHAR(30);
        DECLARE @Monto DECIMAL(10,2);
        DECLARE @Metodo VARCHAR(15);

        -- Bloquear el boleto mientras se valida y anula
        SELECT @Estado = Estado
        FROM dbo.Boletos WITH (UPDLOCK, HOLDLOCK)
        WHERE BoletoID = @BoletoID;

        IF @Estado IS NULL
            THROW 50011, 'El boleto no existe.', 1;

        IF @Estado <> 'Activo'
            THROW 50012, 'El boleto no esta activo.', 1;

        -- Obtener el pago original
        SELECT TOP (1)
            @Monto = Monto,
            @Metodo = Metodo
        FROM dbo.Pagos
        WHERE BoletoID = @BoletoID
          AND Monto > 0
        ORDER BY FechaPago DESC;

        IF @Monto IS NULL
            THROW 50013, 'No se encontro un pago original para el boleto.', 1;

        -- Anular el boleto
        UPDATE dbo.Boletos
        SET Estado = 'Anulado'
        WHERE BoletoID = @BoletoID;

        -- Registrar la reversión con monto negativo
        INSERT INTO dbo.Pagos
            (BoletoID, Monto, Metodo, FechaPago)
        VALUES
            (@BoletoID, -@Monto, @Metodo, SYSDATETIME());

        COMMIT TRANSACTION;

        SELECT
            @BoletoID AS BoletoAnulado,
            -@Monto AS MontoReversado;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
