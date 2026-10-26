/*
  E4 - Seguridad
  Grupo: 8
*/

-- Seleccionar la base de datos del proyecto.
USE BusRD;
GO

-- Evitar mensajes de filas afectadas.
SET NOCOUNT ON;
GO

-- Validar que existan los procedimientos requeridos.
IF OBJECT_ID('dbo.sp_VenderBoleto', 'P') IS NULL
    THROW 50100, 'Debe crear dbo.sp_VenderBoleto antes de ejecutar E4.', 1;

IF OBJECT_ID('dbo.sp_AnularBoleto', 'P') IS NULL
    THROW 50101, 'Debe crear dbo.sp_AnularBoleto antes de ejecutar E4.', 1;
GO

-- Exponer los asientos disponibles de los viajes programados.
CREATE OR ALTER VIEW dbo.vw_AsientosDisponibles
AS
    SELECT
        v.ViajeID,
        r.Origen,
        r.Destino,
        v.FechaSalida,
        s.NumeroAsiento,
        s.Ubicacion
    FROM dbo.Viajes AS v
    JOIN dbo.Rutas AS r
        ON r.RutaID = v.RutaID
    JOIN dbo.Asientos AS s
        ON s.AutobusID = v.AutobusID
    WHERE v.Estado = 'Programado'
      AND NOT EXISTS
      (
          SELECT 1
          FROM dbo.Boletos AS b
          WHERE b.ViajeID = v.ViajeID
            AND b.NumeroAsiento = s.NumeroAsiento
            AND b.Estado = 'Activo'
      );
GO

-- Exponer las ventas mensuales sin datos personales de clientes.
CREATE OR ALTER VIEW dbo.vw_VentasMensuales
AS
    SELECT
        YEAR(b.FechaVenta) AS Anio,
        MONTH(b.FechaVenta) AS Mes,
        r.Origen,
        r.Destino,
        COUNT(*) AS Boletos,
        SUM(p.Monto) AS Ingresos
    FROM dbo.Boletos AS b
    JOIN dbo.Pagos AS p
        ON p.BoletoID = b.BoletoID
    JOIN dbo.Viajes AS v
        ON v.ViajeID = b.ViajeID
    JOIN dbo.Rutas AS r
        ON r.RutaID = v.RutaID
    WHERE b.Estado = 'Activo'
    GROUP BY
        YEAR(b.FechaVenta),
        MONTH(b.FechaVenta),
        r.Origen,
        r.Destino;
GO

-- Crear los roles de la aplicación si no existen.
IF DATABASE_PRINCIPAL_ID('rol_taquilla') IS NULL
    CREATE ROLE rol_taquilla AUTHORIZATION dbo;

IF DATABASE_PRINCIPAL_ID('rol_reportes') IS NULL
    CREATE ROLE rol_reportes AUTHORIZATION dbo;

IF DATABASE_PRINCIPAL_ID('rol_admin') IS NULL
    CREATE ROLE rol_admin AUTHORIZATION dbo;
GO

-- Permitir a taquilla operar mediante procedimientos y consultar la vista.
GRANT EXECUTE ON OBJECT::dbo.sp_VenderBoleto TO rol_taquilla;
GRANT EXECUTE ON OBJECT::dbo.sp_AnularBoleto TO rol_taquilla;
GRANT SELECT ON OBJECT::dbo.vw_AsientosDisponibles TO rol_taquilla;

-- Impedir a taquilla el acceso directo a las tablas.
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.Rutas TO rol_taquilla;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.Autobuses TO rol_taquilla;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.Asientos TO rol_taquilla;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.Viajes TO rol_taquilla;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.Clientes TO rol_taquilla;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.Boletos TO rol_taquilla;
DENY SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.Pagos TO rol_taquilla;
GO

-- Permitir a reportes consultar únicamente la vista mensual.
GRANT SELECT ON OBJECT::dbo.vw_VentasMensuales TO rol_reportes;

-- Impedir a reportes consultar tablas o ejecutar operaciones de venta.
DENY SELECT ON OBJECT::dbo.Rutas TO rol_reportes;
DENY SELECT ON OBJECT::dbo.Autobuses TO rol_reportes;
DENY SELECT ON OBJECT::dbo.Asientos TO rol_reportes;
DENY SELECT ON OBJECT::dbo.Viajes TO rol_reportes;
DENY SELECT ON OBJECT::dbo.Clientes TO rol_reportes;
DENY SELECT ON OBJECT::dbo.Boletos TO rol_reportes;
DENY SELECT ON OBJECT::dbo.Pagos TO rol_reportes;
DENY EXECUTE ON OBJECT::dbo.sp_VenderBoleto TO rol_reportes;
DENY EXECUTE ON OBJECT::dbo.sp_AnularBoleto TO rol_reportes;
GO

-- Conceder al administrador control completo dentro de BusRD.
GRANT CONTROL ON DATABASE::BusRD TO rol_admin;
GO

-- Crear usuarios de prueba sin login para cada rol.
IF DATABASE_PRINCIPAL_ID('usr_taquilla') IS NULL
    CREATE USER usr_taquilla WITHOUT LOGIN;

IF DATABASE_PRINCIPAL_ID('usr_reportes') IS NULL
    CREATE USER usr_reportes WITHOUT LOGIN;

IF DATABASE_PRINCIPAL_ID('usr_admin') IS NULL
    CREATE USER usr_admin WITHOUT LOGIN;
GO

-- Asignar el usuario de taquilla a su rol.
IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_role_members AS drm
    JOIN sys.database_principals AS r
        ON r.principal_id = drm.role_principal_id
    JOIN sys.database_principals AS u
        ON u.principal_id = drm.member_principal_id
    WHERE r.name = 'rol_taquilla'
      AND u.name = 'usr_taquilla'
)
    ALTER ROLE rol_taquilla ADD MEMBER usr_taquilla;

-- Asignar el usuario de reportes a su rol.
IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_role_members AS drm
    JOIN sys.database_principals AS r
        ON r.principal_id = drm.role_principal_id
    JOIN sys.database_principals AS u
        ON u.principal_id = drm.member_principal_id
    WHERE r.name = 'rol_reportes'
      AND u.name = 'usr_reportes'
)
    ALTER ROLE rol_reportes ADD MEMBER usr_reportes;

-- Asignar el usuario administrador a su rol.
IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_role_members AS drm
    JOIN sys.database_principals AS r
        ON r.principal_id = drm.role_principal_id
    JOIN sys.database_principals AS u
        ON u.principal_id = drm.member_principal_id
    WHERE r.name = 'rol_admin'
      AND u.name = 'usr_admin'
)
    ALTER ROLE rol_admin ADD MEMBER usr_admin;
GO

-- Probar los permisos del usuario de taquilla.
EXECUTE AS USER = 'usr_taquilla';

-- Identificar el usuario que ejecuta las pruebas.
SELECT USER_NAME() AS UsuarioActual;

-- Comprobar el acceso permitido a la vista de asientos.
SELECT TOP (5) *
FROM dbo.vw_AsientosDisponibles
ORDER BY ViajeID, NumeroAsiento;
-- Comprobar los permisos de ejecución sobre venta y anulación.
SELECT
    HAS_PERMS_BY_NAME('dbo.sp_VenderBoleto', 'OBJECT', 'EXECUTE') AS PuedeVender,
    HAS_PERMS_BY_NAME('dbo.sp_AnularBoleto', 'OBJECT', 'EXECUTE') AS PuedeAnular;
-- Comprobar que taquilla no pueda consultar Clientes directamente.
BEGIN TRY
    SELECT TOP (1) * FROM dbo.Clientes;
    SELECT 'ERROR: acceso directo a Clientes permitido' AS Resultado;
END TRY
BEGIN CATCH
    SELECT 'DENEGADO' AS Resultado, ERROR_MESSAGE() AS Detalle;
END CATCH;
-- Comprobar que taquilla no pueda eliminar boletos directamente.
BEGIN TRY
    DELETE FROM dbo.Boletos WHERE 1 = 0;
    SELECT 'ERROR: DELETE directo permitido' AS Resultado;
END TRY
BEGIN CATCH
    SELECT 'DENEGADO' AS Resultado, ERROR_MESSAGE() AS Detalle;
END CATCH;
-- Restaurar el contexto de seguridad original.
REVERT;
GO

-- Probar los permisos del usuario de reportes.
EXECUTE AS USER = 'usr_reportes';

-- Identificar el usuario que ejecuta las pruebas.
SELECT USER_NAME() AS UsuarioActual;

-- Comprobar el acceso permitido a la vista mensual.
SELECT TOP (5) *
FROM dbo.vw_VentasMensuales
WHERE Anio = 2025
ORDER BY Origen, Destino, Mes;
-- Comprobar que reportes pueda agregar datos de la vista.
SELECT
    COUNT(*) AS GruposMensuales2025,
    SUM(Ingresos) AS Ingresos2025
FROM dbo.vw_VentasMensuales
WHERE Anio = 2025;
-- Comprobar que reportes no pueda consultar datos personales.
BEGIN TRY
    SELECT TOP (1) Email, Telefono FROM dbo.Clientes;
    SELECT 'ERROR: datos personales expuestos' AS Resultado;
END TRY
BEGIN CATCH
    SELECT 'DENEGADO' AS Resultado, ERROR_MESSAGE() AS Detalle;
END CATCH;
-- Comprobar que reportes no pueda ejecutar una venta.
BEGIN TRY
    DECLARE @BoletoID INT;
    EXEC dbo.sp_VenderBoleto
        @ViajeID = 15254,
        @NumeroAsiento = 1,
        @ClienteID = 8000,
        @Canal = 'Taquilla',
        @Metodo = 'Efectivo',
        @BoletoID = @BoletoID OUTPUT;
    SELECT 'ERROR: venta permitida a reportes' AS Resultado;
END TRY
BEGIN CATCH
    SELECT 'DENEGADO' AS Resultado, ERROR_MESSAGE() AS Detalle;
END CATCH;
-- Restaurar el contexto de seguridad original.
REVERT;
GO

-- Probar los permisos y límites del usuario administrador.
EXECUTE AS USER = 'usr_admin';

-- Identificar el usuario y comprobar la lectura directa de tablas.
SELECT USER_NAME() AS UsuarioActual;
SELECT COUNT(*) AS TotalClientes FROM dbo.Clientes;

-- Comprobar que el administrador pueda crear y eliminar objetos.
CREATE TABLE dbo.PruebaPermisoAdmin
(
    PruebaID INT NOT NULL
);
SELECT 'PERMITIDO' AS Resultado,
       'Creación de objetos dentro de BusRD' AS Detalle;
DROP TABLE dbo.PruebaPermisoAdmin;
SELECT 'PERMITIDO' AS Resultado,
       'Eliminación de objetos dentro de BusRD' AS Detalle;

-- Comprobar el control administrativo dentro de la base.
SELECT
    HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'CONTROL') AS ControlBase;

-- Comprobar que el administrador de la base no pueda crear logins.
BEGIN TRY
    EXEC
    (
        'CREATE LOGIN E4_Login_Prueba
         WITH PASSWORD = ''E4_Prueba_2026!Segura'''
    );
    EXEC ('DROP LOGIN E4_Login_Prueba');
    SELECT 'ERROR: creación de login permitida' AS Resultado;
END TRY
BEGIN CATCH
    SELECT 'DENEGADO' AS Resultado, ERROR_MESSAGE() AS Detalle;
END CATCH;

-- Comprobar que el administrador de la base no pueda crear roles de servidor.
BEGIN TRY
    EXEC ('CREATE SERVER ROLE E4_RolServidor_Prueba');
    EXEC ('DROP SERVER ROLE E4_RolServidor_Prueba');
    SELECT 'ERROR: creación de rol de servidor permitida' AS Resultado;
END TRY
BEGIN CATCH
    SELECT 'DENEGADO' AS Resultado, ERROR_MESSAGE() AS Detalle;
END CATCH;

-- Restaurar el contexto de seguridad original.
REVERT;
GO
