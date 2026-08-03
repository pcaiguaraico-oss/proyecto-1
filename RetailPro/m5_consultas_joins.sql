-- ============================================
-- m5_consultas_joins.sql - RetailPro / TechStore
-- Pre-entrega: Consultas con JOINs y UNION ALL (Modulo 5)
-- ============================================
-- NOTA sobre el esquema: la base creada en M3 (ventas_tech_db.sql) no tiene
-- columna de "segmento" de cliente, ni tabla de "territorios"/region, ni un
-- canal de venta (Online/Presencial) guardado en la tabla ventas. Para que
-- las consultas corran sobre los datos reales de este proyecto:
--   - "region" se resuelve con clientes.ciudad (el unico dato geografico
--     que existe en la base).
--   - "segmento" no se incluye: no hay ningun campo que lo represente.
--   - "canal" (Consulta 4) se genera DENTRO de la propia consulta con
--     UNION ALL, separando las ventas por id_venta par/impar solo para
--     practicar la sintaxis, ya que la tabla ventas no guarda un canal real.

-- Consulta 1: Vista base del proyecto (INNER JOIN)
-- Junta ventas + clientes + productos + categorias en una sola fila.
-- Esta es la consulta que va a alimentar Power BI en M7.
SELECT
    v.fecha_venta,
    c.nombre              AS cliente,
    c.ciudad               AS region,
    p.nombre_producto,
    cat.nombre_categoria   AS categoria,
    v.cantidad,
    v.precio_unitario,
    (v.cantidad * v.precio_unitario) AS total_venta
FROM ventas v
INNER JOIN clientes c     ON v.id_cliente = c.id_cliente
INNER JOIN productos p    ON v.id_producto = p.id_producto
INNER JOIN categorias cat ON p.id_categoria = cat.id_categoria
ORDER BY v.fecha_venta;

-- Consulta 2: Clientes sin ventas (LEFT JOIN)
SELECT
    c.nombre,
    c.email,
    c.fecha_registro
FROM clientes c
LEFT JOIN ventas v ON c.id_cliente = v.id_cliente
WHERE v.id_venta IS NULL;

-- Consulta 3: Productos sin ventas (LEFT JOIN)
SELECT
    p.nombre_producto,
    cat.nombre_categoria AS categoria,
    p.precio
FROM productos p
LEFT JOIN categorias cat ON p.id_categoria = cat.id_categoria
LEFT JOIN ventas v        ON p.id_producto = v.id_producto
WHERE v.id_venta IS NULL;

-- Consulta 4: Consolidado por canal (UNION ALL)
-- Ventas con id_venta par -> "Online"; id_venta impar -> "Presencial".
-- (division ilustrativa para practicar UNION ALL, ver nota de arriba)
SELECT
    v.id_venta,
    v.fecha_venta,
    v.cantidad,
    v.precio_unitario,
    (v.cantidad * v.precio_unitario) AS total_venta,
    'Online' AS canal
FROM ventas v
WHERE v.id_venta % 2 = 0
UNION ALL
SELECT
    v.id_venta,
    v.fecha_venta,
    v.cantidad,
    v.precio_unitario,
    (v.cantidad * v.precio_unitario) AS total_venta,
    'Presencial' AS canal
FROM ventas v
WHERE v.id_venta % 2 <> 0
ORDER BY id_venta;

-- Total facturado por canal (mismo UNION ALL de arriba, agregado con GROUP BY)
SELECT
    canal,
    COUNT(*)         AS cantidad_ventas,
    SUM(total_venta) AS total_por_canal
FROM (
      SELECT
          (v.cantidad * v.precio_unitario) AS total_venta,
          'Online' AS canal
      FROM ventas v
      WHERE v.id_venta % 2 = 0
      UNION ALL
      SELECT
          (v.cantidad * v.precio_unitario) AS total_venta,
          'Presencial' AS canal
      FROM ventas v
      WHERE v.id_venta % 2 <> 0
  ) AS ventas_por_canal
GROUP BY canal
ORDER BY canal;
