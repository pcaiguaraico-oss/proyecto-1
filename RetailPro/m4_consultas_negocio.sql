-- ============================================
-- m4_consultas_negocio.sql - RetailPro / TechStore
-- Pre-entrega: Consultas SQL de negocio (Modulo 4)
-- ============================================

-- Consulta 1: Resumen ejecutivo mensual
SELECT
    EXTRACT(MONTH FROM fecha_venta) AS mes,
    SUM(cantidad * precio_unitario)  AS total_facturado,
    COUNT(*)                        AS cantidad_pedidos,
    AVG(cantidad * precio_unitario)  AS ticket_promedio
FROM ventas
GROUP BY EXTRACT(MONTH FROM fecha_venta)
ORDER BY mes;

-- Consulta 2: Ranking de productos (top 5 por total facturado)
SELECT
    id_producto,
    SUM(cantidad)                   AS unidades_vendidas,
    SUM(cantidad * precio_unitario)  AS total_facturado
FROM ventas
GROUP BY id_producto
ORDER BY total_facturado DESC
LIMIT 5;

-- Consulta 3: Clientes recurrentes (mas de un pedido)
SELECT
    id_cliente,
    COUNT(*)                        AS cantidad_pedidos,
    SUM(cantidad * precio_unitario)  AS total_gastado
FROM ventas
GROUP BY id_cliente
HAVING COUNT(*) > 1
ORDER BY total_gastado DESC;

-- Consulta 4: Meses por encima/por debajo del promedio
WITH ventas_por_mes AS (
      SELECT
          EXTRACT(MONTH FROM fecha_venta) AS mes,
          SUM(cantidad * precio_unitario)  AS total_facturado
      FROM ventas
      GROUP BY EXTRACT(MONTH FROM fecha_venta)
  )
SELECT
    mes,
    total_facturado,
    CASE
        WHEN total_facturado >= (SELECT AVG(total_facturado) FROM ventas_por_mes) THEN 'Por encima'
        ELSE 'Por debajo'
    END AS comparacion_promedio
FROM ventas_por_mes
ORDER BY mes;

-- Hallazgos:
-- 1. El producto 1 (Laptop Pro 15) concentra el 55.9% de la facturacion total
--    (3600 de 6444), siendo el mas rentable con solo 3 unidades vendidas.
-- 2. Los 5 clientes cargados hicieron exactamente 2 pedidos cada uno, por lo que
--    los 5 aparecen como clientes recurrentes: no hay compradores de una sola vez.
-- 3. Todas las ventas cargadas hasta ahora son de marzo 2024 (un solo mes), asi que
--    la comparacion por encima/por debajo del promedio todavia no es representativa;
--    va a mostrar variacion real recien cuando se carguen ventas de otros meses.
