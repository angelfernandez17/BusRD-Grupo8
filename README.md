# BusRD — Grupo 8

Trabajo final de **ISW-323 Taller de Base de Datos III** sobre integridad,
concurrencia, optimización, seguridad y recuperación en SQL Server 2022.

## Integrantes

| Nombre | Matrícula | Responsabilidad principal |
|---|---|---|
| José Constanza | A00159462 | E1, E5 |
| Keymer Jorge Valenzuela | A00150536 | E2 |
| Angel Fernandez | A00177007 | E3, E4, E6 |

## Datos asignados

| Dato | Valor |
|---|---|
| Grupo | 8 |
| Cédula para C2 | `40200008000` |
| Viaje asignado para C1 | `15254` |
| Motor | SQL Server 2022 Developer o Express |
| Herramienta | SQL Server Management Studio (SSMS) |

El `ViajeID = 16000` del script original del docente es solamente un ejemplo. El
grupo 8 utiliza `ViajeID = 15254` para C1.

## Estructura

```text
BusRD-Grupo8/
├── evidencias/
│   └── README.md
├── scripts/
│   ├── 00_BusRD_base.sql
│   ├── 01_Integridad.sql
│   ├── 02_sp_VenderBoleto.sql
│   ├── 03_sp_AnularBoleto.sql
│   ├── 04_demo_concurrencia_sesionA.sql
│   ├── 05_demo_concurrencia_sesionB.sql
│   ├── 06_indices_y_consultas_optimizadas.sql
│   ├── 07_seguridad.sql
│   └── 08_Respaldo_y_recuperacion.sql
├── .gitignore
└── README.md
```

## Recursos base

El docente proporcionó originalmente:

1. `01_BusRD_base.sql`: creación y carga de datos.
2. `02_sp_VenderBoleto_v0.sql`: procedimiento defectuoso para reproducir la
   doble venta.
3. `03_consultas_lentas.sql`: consultas originales C1, C2 y C3.

En este repositorio, la copia del script de creación y carga se encuentra como
`scripts/00_BusRD_base.sql`. Los scripts originales de doble venta y consultas
lentas se utilizan para obtener las evidencias previas, pero no sustituyen las
soluciones numeradas del grupo.

## Preparación de evidencias iniciales

Estas pruebas deben realizarse antes de ejecutar `01_Integridad.sql`:

1. Ejecutar `scripts/00_BusRD_base.sql` para recrear `BusRD`.
2. Ejecutar el procedimiento defectuoso `sp_VenderBoleto_v0` en dos sesiones y
   capturar la doble venta.
3. Ejecutar las tres consultas originales de `03_consultas_lentas.sql` con plan
   real y `STATISTICS IO/TIME` para guardar la línea base de E3.

Este orden es importante porque E1 crea restricciones e índices que impiden la
doble venta y pueden modificar los planes originales de E3.

## Orden de ejecución de las soluciones

Después de guardar las evidencias iniciales, ejecutar:

1. `scripts/01_Integridad.sql`
   - Limpia boletos duplicados y pagos huérfanos.
   - Crea llaves foráneas, restricciones y unicidad.
2. `scripts/02_sp_VenderBoleto.sql`
   - Crea el procedimiento transaccional de venta.
3. `scripts/03_sp_AnularBoleto.sql`
   - Crea el procedimiento transaccional de anulación y reverso.
4. Abrir dos ventanas de SSMS y ejecutar simultáneamente:
   - Sesión A: `scripts/04_demo_concurrencia_sesionA.sql`.
   - Sesión B: `scripts/05_demo_concurrencia_sesionB.sql`.
5. `scripts/06_indices_y_consultas_optimizadas.sql`
   - Crea los índices de E3 que no hayan sido creados por E1.
   - Ejecuta las consultas optimizadas y las pruebas de equivalencia.
6. `scripts/07_seguridad.sql`
   - Crea vistas, roles, usuarios sin login y pruebas de permisos.
7. `scripts/08_Respaldo_y_recuperacion.sql`
   - Ejecuta la secuencia de respaldo y recuperación de E5.

## Consideraciones de ejecución

### Integración entre E1 y E3

Para evitar índices redundantes, E1 debe usar estos nombres:

```text
UX_Boletos_Viaje_Asiento_Activo
UX_Clientes_Cedula
```

`06_indices_y_consultas_optimizadas.sql` detecta esos índices y no crea sus
alternativas si ya existen.

### Demostración de concurrencia

Los archivos `04_demo_concurrencia_sesionA.sql` y
`05_demo_concurrencia_sesionB.sql` deben contener las llamadas definitivas con
el mismo viaje y asiento libre antes de la entrega. Actualmente deben revisarse
porque solo contienen la configuración inicial de la sesión.


## Validación final

Antes de entregar:

1. Recrear la base con `scripts/00_BusRD_base.sql`.
2. Obtener las evidencias que necesariamente ocurren antes de E1.
3. Ejecutar los scripts de solución en el orden documentado.
4. Confirmar que no existan errores.
5. Verificar que las comparaciones de E3 devuelvan cero diferencias.
6. Verificar los accesos permitidos y denegados de E4.
7. Confirmar la restauración de E5 hasta el momento indicado.

## Evidencias

Las capturas se almacenan en [`evidencias/`](evidencias/README.md) con nombres
numerados y deben ser referenciadas desde el informe.
