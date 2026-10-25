# BusRD — Grupo 8

Trabajo final de **ISW-323 Taller de Base de Datos III** sobre integridad,
concurrencia, optimización, seguridad y recuperación en SQL Server 2022.

## Integrantes

| Nombre | Matrícula | Responsabilidad principal |
|---|---|---|
| Pendiente | Pendiente | Pendiente |
| Pendiente | Pendiente | Pendiente |
| Pendiente | Pendiente | Pendiente |


## Datos asignados

| Dato | Valor |
|---|---|
| Grupo | 8 |
| Cédula para C2 | `40200008000` |
| Viaje asignado para C1 y demos |  |
| Motor | SQL Server 2022 Developer o Express |
| Herramienta | SQL Server Management Studio (SSMS) |

El `ViajeID = 16000` del script entregado es un ejemplo.

## Estructura

```text
BusRD-Grupo8/
├── evidencias/
│   └── README.md
├── scripts/
│   ├── 01_integridad.sql
│   ├── 02_sp_VenderBoleto.sql
│   ├── 03_sp_AnularBoleto.sql
│   ├── 04_demo_concurrencia_sesionA.sql
│   ├── 05_demo_concurrencia_sesionB.sql
│   ├── 06_indices_y_consultas_optimizadas.sql
│   ├── 07_seguridad.sql
│   └── 08_respaldo_y_restauracion.sql
├── .gitignore
└── README.md
```

## Recursos base

Antes de ejecutar los scripts del repositorio, el docente proporciona:

1. `01_BusRD_base.sql`: crea la base y carga los datos.
2. `02_sp_VenderBoleto_v0.sql`: procedimiento defectuoso para la demostración.
3. `03_consultas_lentas.sql`: línea base de las consultas C1, C2 y C3.


## Orden de ejecución

1. Ejecutar el recurso base `01_BusRD_base.sql` en una instancia de pruebas.
2. Ejecutar `02_sp_VenderBoleto_v0.sql` y obtener la evidencia de doble venta.
3. Ejecutar `scripts/01_integridad.sql` en el punto indicado por su encabezado.
4. Ejecutar `scripts/02_sp_VenderBoleto.sql`.
5. Ejecutar `scripts/03_sp_AnularBoleto.sql`.
6. Abrir dos ventanas de SSMS y ejecutar los scripts 04 y 05 según sus
   instrucciones.
7. Ejecutar `scripts/06_indices_y_consultas_optimizadas.sql` después de guardar
   las métricas de línea base.
8. Ejecutar `scripts/07_seguridad.sql`.
9. Ejecutar `scripts/08_respaldo_y_restauracion.sql` adaptando únicamente las
   rutas de respaldo documentadas.


## Evidencias

Las capturas se almacenan en [`evidencias/`](evidencias/README.md) con nombres
numerados.


## Estado

- [ ] E1 — Integridad del modelo
- [ ] E2 — Venta transaccional y concurrencia
- [ ] E3 — Optimización
- [ ] E4 — Seguridad
- [ ] E5 — Respaldo y recuperación
- [ ] E6 — Informe, evidencias y validación del repositorio
