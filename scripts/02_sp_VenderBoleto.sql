/*
  E2 - Procedimiento transaccional de venta
  Grupo: 8
*/

USE BusRD;
GO

CREATE OR ALTER PROCEDURE dbo.sp_VenderBoleto
    @ViajeID       INT,
    @NumeroAsiento INT,
    @ClienteID     INT,
    @Canal         VARCHAR(10),
    @Metodo        VARCHAR(15),
    @BoletoID      INT OUTPUT,
    @SimularDemora BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @BoletoID = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @AutobusID INT;
        DECLARE @EstadoViaje VARCHAR(30);
        DECLARE @Precio DECIMAL(10,2);

        -- Validar que el viaje exista y obtener su información
        SELECT
            @AutobusID = v.AutobusID,
            @EstadoViaje = v.Estado,
            @Precio = 350.00
        FROM dbo.Viajes AS v
        INNER JOIN dbo.Rutas AS r
            ON r.RutaID = v.RutaID
        WHERE v.ViajeID = @ViajeID;

        IF @AutobusID IS NULL
            THROW 50001, 'El viaje no existe.', 1;

            IF @Precio < 350.00
    THROW 50008, 'El precio minimo del boleto es RD$350.00.', 1;

        IF @EstadoViaje <> 'Programado'
            THROW 50002, 'El viaje no esta programado.', 1;

        -- Validar que el asiento pertenezca al autobus del viaje
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Asientos
            WHERE AutobusID = @AutobusID
              AND NumeroAsiento = @NumeroAsiento
        )
            THROW 50003, 'El asiento no pertenece al autobus del viaje.', 1;

        -- Validar que el cliente exista
        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Clientes
            WHERE ClienteID = @ClienteID
        )
            THROW 50004, 'El cliente no existe.', 1;

        -- Validar el canal de venta
        IF @Canal IS NULL
           OR @Canal NOT IN ('Web', 'Taquilla')
            THROW 50005, 'El canal de venta no es valido.', 1;

    
        -- Validar el metodo de pago
        IF @Metodo IS NULL
           OR @Metodo NOT IN ('Efectivo', 'Tarjeta', 'Transferencia')
            THROW 50006, 'El metodo de pago no es valido.', 1;


        -- Bloquear la comprobacion para evitar ventas simultaneas
        IF EXISTS (
            SELECT 1
            FROM dbo.Boletos WITH (UPDLOCK, HOLDLOCK)
            WHERE ViajeID = @ViajeID
              AND NumeroAsiento = @NumeroAsiento
              AND Estado = 'Activo'
        )
            THROW 50007, 'El asiento ya esta vendido.', 1;

        -- Demora opcional para demostrar la concurrencia
        IF @SimularDemora = 1
            WAITFOR DELAY '00:00:10';

        -- Registrar el boleto
        INSERT INTO dbo.Boletos
            (ViajeID, NumeroAsiento, ClienteID,
             FechaVenta, Canal, Precio, Estado)
        VALUES
            (@ViajeID, @NumeroAsiento, @ClienteID,
             SYSDATETIME(), @Canal, @Precio, 'Activo');

        SET @BoletoID = CONVERT(INT, SCOPE_IDENTITY());

        -- Registrar el pago en la misma transaccion
        INSERT INTO dbo.Pagos
            (BoletoID, Monto, Metodo, FechaPago)
        VALUES
            (@BoletoID, @Precio, @Metodo, SYSDATETIME());

        COMMIT TRANSACTION;

        SELECT @BoletoID AS BoletoID;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        SET @BoletoID = NULL;
        THROW;
    END CATCH;
END;
GO
