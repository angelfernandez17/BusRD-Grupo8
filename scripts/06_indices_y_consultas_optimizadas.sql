/*
  E3 - Índices y consultas optimizadas
  Grupo: 8
*/

-- Seleccionar la base de datos del proyecto.
USE BusRD;
GO

-- Configurar la ejecución segura del script.
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- Acelerar la búsqueda de asientos vendidos en cada viaje.
IF INDEXPROPERTY(
       OBJECT_ID('dbo.Boletos'),
       'UX_Boletos_Viaje_Asiento_Activo',
       'IndexID'
   ) IS NULL
   AND INDEXPROPERTY(
       OBJECT_ID('dbo.Boletos'),
       'IX_Boletos_Viaje_Asiento_Activo',
       'IndexID'
   ) IS NULL
BEGIN
    CREATE INDEX IX_Boletos_Viaje_Asiento_Activo
        ON dbo.Boletos (ViajeID, NumeroAsiento)
        WHERE Estado = 'Activo';
END;
GO

-- Buscar clientes por cédula y garantizar su unicidad.
IF INDEXPROPERTY(
       OBJECT_ID('dbo.Clientes'),
       'UX_Clientes_Cedula',
       'IndexID'
   ) IS NULL
BEGIN
    CREATE UNIQUE INDEX UX_Clientes_Cedula
        ON dbo.Clientes (Cedula)
        INCLUDE (Nombre, Apellido);
END;
GO

-- Localizar el historial de boletos de un cliente.
IF INDEXPROPERTY(
       OBJECT_ID('dbo.Boletos'),
       'IX_Boletos_Cliente',
       'IndexID'
   ) IS NULL
BEGIN
    CREATE INDEX IX_Boletos_Cliente
        ON dbo.Boletos (ClienteID)
        INCLUDE (ViajeID, NumeroAsiento, Precio, Estado);
END;
GO

-- Buscar boletos activos dentro de un rango de fechas.
IF INDEXPROPERTY(
       OBJECT_ID('dbo.Boletos'),
       'IX_Boletos_FechaVenta_Activos',
       'IndexID'
   ) IS NULL
BEGIN
    CREATE INDEX IX_Boletos_FechaVenta_Activos
        ON dbo.Boletos (FechaVenta)
        INCLUDE (ViajeID)
        WHERE Estado = 'Activo';
END;
GO

-- Acelerar la unión entre boletos y pagos.
IF INDEXPROPERTY(
       OBJECT_ID('dbo.Pagos'),
       'IX_Pagos_Boleto',
       'IndexID'
   ) IS NULL
BEGIN
    CREATE INDEX IX_Pagos_Boleto
        ON dbo.Pagos (BoletoID)
        INCLUDE (Monto);
END;
GO

-- Activar las métricas de rendimiento de las consultas optimizadas.
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- C1: consultar los asientos disponibles mediante NOT EXISTS.
DECLARE @ViajeID INT = 15254;

SELECT
    s.NumeroAsiento,
    s.Ubicacion
FROM dbo.Viajes AS v
JOIN dbo.Asientos AS s
    ON s.AutobusID = v.AutobusID
WHERE v.ViajeID = @ViajeID
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.Boletos AS b
      WHERE b.ViajeID = @ViajeID
        AND b.NumeroAsiento = s.NumeroAsiento
        AND b.Estado = 'Activo'
  )
ORDER BY s.NumeroAsiento;
GO

-- C2: consultar el historial con un predicado sargable por cédula.
DECLARE @Cedula CHAR(11) = '40200008000';

SELECT
    c.Nombre,
    c.Apellido,
    r.Origen,
    r.Destino,
    v.FechaSalida,
    b.NumeroAsiento,
    b.Precio,
    b.Estado
FROM dbo.Clientes AS c
JOIN dbo.Boletos AS b
    ON b.ClienteID = c.ClienteID
JOIN dbo.Viajes AS v
    ON v.ViajeID = b.ViajeID
JOIN dbo.Rutas AS r
    ON r.RutaID = v.RutaID
WHERE c.Cedula = @Cedula
ORDER BY v.FechaSalida DESC;
GO

-- C3: calcular las ventas de 2025 usando un rango sargable.
SELECT
    r.Origen,
    r.Destino,
    MONTH(b.FechaVenta) AS Mes,
    COUNT(*) AS Boletos,
    SUM(p.Monto) AS Ingresos
FROM dbo.Boletos AS b
JOIN dbo.Pagos AS p
    ON p.BoletoID = b.BoletoID
JOIN dbo.Viajes AS v
    ON v.ViajeID = b.ViajeID
JOIN dbo.Rutas AS r
    ON r.RutaID = v.RutaID
WHERE b.FechaVenta >= CONVERT(DATETIME2(0), '20250101', 112)
  AND b.FechaVenta <  CONVERT(DATETIME2(0), '20260101', 112)
  AND b.Estado = 'Activo'
GROUP BY
    r.Origen,
    r.Destino,
    MONTH(b.FechaVenta)
ORDER BY
    r.Origen,
    r.Destino,
    Mes;
GO

-- Desactivar las métricas al finalizar las mediciones.
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- Validar que las versiones original y optimizada de C1 sean equivalentes.
DECLARE @ViajeID INT = 15254;

-- Guardar el resultado original de C1.
SELECT
    s.NumeroAsiento,
    s.Ubicacion
INTO #C1Original
FROM dbo.Viajes AS v
JOIN dbo.Asientos AS s
    ON s.AutobusID = v.AutobusID
WHERE v.ViajeID = @ViajeID
  AND s.NumeroAsiento NOT IN
  (
      SELECT b.NumeroAsiento
      FROM dbo.Boletos AS b
      WHERE b.ViajeID = @ViajeID
        AND b.Estado = 'Activo'
  );

-- Guardar el resultado optimizado de C1.
SELECT
    s.NumeroAsiento,
    s.Ubicacion
INTO #C1Optimizada
FROM dbo.Viajes AS v
JOIN dbo.Asientos AS s
    ON s.AutobusID = v.AutobusID
WHERE v.ViajeID = @ViajeID
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.Boletos AS b
      WHERE b.ViajeID = @ViajeID
        AND b.NumeroAsiento = s.NumeroAsiento
        AND b.Estado = 'Activo'
  );

-- Contar filas y diferencias en ambas direcciones para C1.
SELECT
    'C1' AS Consulta,
    (SELECT COUNT(*) FROM #C1Original) AS FilasOriginal,
    (SELECT COUNT(*) FROM #C1Optimizada) AS FilasOptimizada,
    (SELECT COUNT(*)
     FROM
     (
         SELECT NumeroAsiento, Ubicacion FROM #C1Original
         EXCEPT
         SELECT NumeroAsiento, Ubicacion FROM #C1Optimizada
     ) AS d) AS SoloOriginal,
    (SELECT COUNT(*)
     FROM
     (
         SELECT NumeroAsiento, Ubicacion FROM #C1Optimizada
         EXCEPT
         SELECT NumeroAsiento, Ubicacion FROM #C1Original
     ) AS d) AS SoloOptimizada;
GO

-- Validar que las versiones original y optimizada de C2 sean equivalentes.
DECLARE @Cedula CHAR(11) = '40200008000';

-- Guardar el resultado original de C2.
SELECT
    c.Nombre,
    c.Apellido,
    r.Origen,
    r.Destino,
    v.FechaSalida,
    b.NumeroAsiento,
    b.Precio,
    b.Estado
INTO #C2Original
FROM dbo.Clientes AS c
JOIN dbo.Boletos AS b
    ON b.ClienteID = c.ClienteID
JOIN dbo.Viajes AS v
    ON v.ViajeID = b.ViajeID
JOIN dbo.Rutas AS r
    ON r.RutaID = v.RutaID
WHERE LTRIM(RTRIM(c.Cedula)) = @Cedula;

-- Guardar el resultado optimizado de C2.
SELECT
    c.Nombre,
    c.Apellido,
    r.Origen,
    r.Destino,
    v.FechaSalida,
    b.NumeroAsiento,
    b.Precio,
    b.Estado
INTO #C2Optimizada
FROM dbo.Clientes AS c
JOIN dbo.Boletos AS b
    ON b.ClienteID = c.ClienteID
JOIN dbo.Viajes AS v
    ON v.ViajeID = b.ViajeID
JOIN dbo.Rutas AS r
    ON r.RutaID = v.RutaID
WHERE c.Cedula = @Cedula;

-- Contar filas y diferencias en ambas direcciones para C2.
SELECT
    'C2' AS Consulta,
    (SELECT COUNT(*) FROM #C2Original) AS FilasOriginal,
    (SELECT COUNT(*) FROM #C2Optimizada) AS FilasOptimizada,
    (SELECT COUNT(*)
     FROM
     (
         SELECT * FROM #C2Original
         EXCEPT
         SELECT * FROM #C2Optimizada
     ) AS d) AS SoloOriginal,
    (SELECT COUNT(*)
     FROM
     (
         SELECT * FROM #C2Optimizada
         EXCEPT
         SELECT * FROM #C2Original
     ) AS d) AS SoloOptimizada;
GO

-- Validar que las versiones original y optimizada de C3 sean equivalentes.

-- Guardar el resultado original de C3.
SELECT
    r.Origen,
    r.Destino,
    MONTH(b.FechaVenta) AS Mes,
    COUNT(*) AS Boletos,
    SUM(p.Monto) AS Ingresos
INTO #C3Original
FROM dbo.Boletos AS b
JOIN dbo.Pagos AS p
    ON p.BoletoID = b.BoletoID
JOIN dbo.Viajes AS v
    ON v.ViajeID = b.ViajeID
JOIN dbo.Rutas AS r
    ON r.RutaID = v.RutaID
WHERE YEAR(b.FechaVenta) = 2025
  AND b.Estado = 'Activo'
GROUP BY
    r.Origen,
    r.Destino,
    MONTH(b.FechaVenta);

-- Guardar el resultado optimizado de C3.
SELECT
    r.Origen,
    r.Destino,
    MONTH(b.FechaVenta) AS Mes,
    COUNT(*) AS Boletos,
    SUM(p.Monto) AS Ingresos
INTO #C3Optimizada
FROM dbo.Boletos AS b
JOIN dbo.Pagos AS p
    ON p.BoletoID = b.BoletoID
JOIN dbo.Viajes AS v
    ON v.ViajeID = b.ViajeID
JOIN dbo.Rutas AS r
    ON r.RutaID = v.RutaID
WHERE b.FechaVenta >= CONVERT(DATETIME2(0), '20250101', 112)
  AND b.FechaVenta <  CONVERT(DATETIME2(0), '20260101', 112)
  AND b.Estado = 'Activo'
GROUP BY
    r.Origen,
    r.Destino,
    MONTH(b.FechaVenta);

-- Contar filas y diferencias en ambas direcciones para C3.
SELECT
    'C3' AS Consulta,
    (SELECT COUNT(*) FROM #C3Original) AS FilasOriginal,
    (SELECT COUNT(*) FROM #C3Optimizada) AS FilasOptimizada,
    (SELECT COUNT(*)
     FROM
     (
         SELECT * FROM #C3Original
         EXCEPT
         SELECT * FROM #C3Optimizada
     ) AS d) AS SoloOriginal,
    (SELECT COUNT(*)
     FROM
     (
         SELECT * FROM #C3Optimizada
         EXCEPT
         SELECT * FROM #C3Original
     ) AS d) AS SoloOptimizada;
GO
