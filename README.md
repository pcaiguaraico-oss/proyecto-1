# Proyecto RetailPro / TechStore — Data Analytics

Proyecto integrador del curso de Data Analytics (Coderhouse). Recorre el ciclo completo
del dato: diseño y carga de una base relacional en SQL, consultas de negocio, y modelado
analítico en Power BI con ETL y medidas DAX.

Autor: Pablo Caiguaraico

---

## Estructura del repositorio

| Carpeta | Contenido | Módulo |
|---|---|---|
| `modulo3/` | `ventas_tech_db.sql` — DDL + carga inicial de `Ventas_Tech_DB` | M3 |
| `RetailPro/` | `m4_consultas_negocio.sql` — agregaciones, `HAVING`, CTE | M4 |
| `RetailPro/` | `m5_consultas_joins.sql` — `INNER`/`LEFT JOIN`, `UNION ALL` | M5 |
| `modulo6/` | `Pipeline_ETL_Caiguaraico_Pablo.pbix` — ETL con Power Query y M | M6 |
| `modulo8/` | `Caiguaraico_Pablo_Checkpoint2.pbix` — modelo, calendario y medidas DAX | M8 |

> Nota sobre la nomenclatura: las entregas de M4 y M5 viven en `RetailPro/` y el resto
> sigue el patrón `moduloN/`. La inconsistencia es histórica; se documenta acá para que
> nadie busque una carpeta `modulo4/` que no existe.

---

## Parte 1 — Base de datos SQL

### Modelo

Cuatro tablas con integridad referencial declarada:

```
categorias ──1:N──▶ productos ──1:N──▶ ventas ◀──1:N── clientes
```

| Tabla | PK | FK |
|---|---|---|
| `categorias` | `id_categoria` | — |
| `clientes` | `id_cliente` | — |
| `productos` | `id_producto` | `id_categoria` → `categorias` |
| `ventas` | `id_venta` | `id_cliente` → `clientes`, `id_producto` → `productos` |

### Cómo ejecutarlo

**Motor: MySQL 8.** El DDL usa `TINYINT(1)` y las consultas de M4 usan
`EXTRACT(MONTH FROM …)`, que no son portables tal cual:

| Motor | Ajuste necesario |
|---|---|
| MySQL / MariaDB | Ninguno, corre tal cual |
| PostgreSQL | Cambiar `TINYINT(1)` por `BOOLEAN` |
| SQL Server | `TINYINT(1)` → `BIT`; `EXTRACT(MONTH FROM x)` → `MONTH(x)` |
| SQLite | `EXTRACT(MONTH FROM x)` → `CAST(strftime('%m', x) AS INTEGER)` |

```bash
# 1. Crear la base
mysql -u usuario -p -e "CREATE DATABASE Ventas_Tech_DB;"

# 2. Estructura y carga (el script hace DROP primero: es idempotente)
mysql -u usuario -p Ventas_Tech_DB < modulo3/ventas_tech_db.sql

# 3. Consultas de negocio
mysql -u usuario -p Ventas_Tech_DB < RetailPro/m4_consultas_negocio.sql
mysql -u usuario -p Ventas_Tech_DB < RetailPro/m5_consultas_joins.sql
```

El orden importa: `ventas_tech_db.sql` borra e inserta respetando las dependencias de FK
(borra de hija a padre, inserta de padre a hija). Correrlo fuera de orden falla por
integridad referencial.

---

## Parte 2 — Power BI

### `modulo6/` — Pipeline ETL

Conecta a `Pipeline_ETL_Dataset.xlsx`, resuelve los problemas de calidad del origen
(1 duplicado y 2 nulos en clientes, 1 duplicado y 2 nulos en productos) y entrega cuatro
consultas tipadas y renombradas: `Dim_Clientes` (11), `Dim_Productos` (12),
`Dim_Categorias` (4) y `Fact_Ventas` (50). Los pasos están renombrados y comentados en el
Editor Avanzado.

### `modulo8/` — Modelo analítico

Toma el `.pbix` anterior y le agrega:

- Cuatro relaciones activas, cardinalidad 1:N y dirección de filtro única.
- `Dim_Fechas` generada con `CALENDARAUTO()`, con columnas calculadas y marcada como
  tabla de fechas (requisito para que funcione la inteligencia temporal).
- Tabla `_Medidas` sin columnas, con cinco medidas: `Total Ventas`, `Ventas Online`,
  `Ventas YTD`, `Ventas LY` y `% Crecimiento Anual`.
- Página `Validación` con una matriz que permite verificar los resultados a ojo.

Detalle del modelado en [`modulo8/README.md`](modulo8/README.md).

---

## Limitaciones de los datos

Esto no es una nota al pie: condiciona qué conclusiones son defendibles.

1. **La base SQL tiene 10 ventas, todas de marzo de 2024.** Cualquier análisis de
   tendencia, estacionalidad o crecimiento sobre `Ventas_Tech_DB` es imposible: hay un
   solo mes. La consulta de "meses por encima/por debajo del promedio" de M4 devuelve una
   sola fila, y va a mostrar variación real recién cuando se carguen más meses.

2. **Los cinco clientes tienen exactamente dos pedidos cada uno.** Es un artefacto del
   dataset de ejemplo, no un patrón de comportamiento. No se puede leer como retención.

3. **El campo `canal` (Online / Presencial) no existe en la base.** Se genera dentro de la
   consulta 4 de M5 separando por `id_venta` par o impar, solo para practicar `UNION ALL`.
   La diferencia de facturación entre ambos "canales" **no significa nada**: es una
   partición arbitraria.

4. **La base SQL y el dataset de Power BI son fuentes distintas.** `Ventas_Tech_DB` tiene
   10 ventas de marzo 2024; `Pipeline_ETL_Dataset.xlsx` tiene 50 ventas entre enero 2023 y
   julio 2024, con 12 clientes y 13 productos. Los totales **no coinciden ni deberían**:
   el `.pbix` no lee de la base SQL.

---

## Herramientas

| Herramienta | Uso |
|---|---|
| MySQL 8 | Base relacional, DDL y consultas |
| Power BI Desktop | ETL (Power Query / M), modelado y DAX |
| Excel | Origen del dataset de Power BI |
| Git / GitHub | Versionado y entrega |
