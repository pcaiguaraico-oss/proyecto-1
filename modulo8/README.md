# Modulo 8 - Modelo de datos con relaciones activas y tabla de medidas core en DAX

Entregable: `Caiguaraico_Pablo_Checkpoint2.pbix`
Parte de: `Pipeline_ETL_Caiguaraico_Pablo.pbix` (modulo 6)
Autor: Pablo Caiguaraico

## Modelo en estrella

Cuatro relaciones, todas activas, cardinalidad 1:N y direccion de filtro unica
(de la dimension hacia los hechos):

| Dimension (1) | Columna | Hechos (N) | Columna |
|---|---|---|---|
| Dim_Clientes | id_cliente | Fact_Ventas | id_cliente |
| Dim_Productos | id_producto | Fact_Ventas | id_producto |
| Dim_Categorias | id_categoria | Dim_Productos | id_categoria |
| Dim_Fechas | Date | Fact_Ventas | fecha_venta |

Ninguna relacion quedo bidireccional: el filtro cruzado en "Ambas" genera
ambiguedad cuando dos caminos distintos llegan a la misma tabla, y las medidas
empiezan a devolver totales que no cuadran.

### Nota sobre id_categoria

El archivo de origen no traia la clave foranea a categorias: `productos` solo
guardaba el nombre de la categoria como texto. En Power Query se recupera el
`id_categoria` cruzando `Dim_Productos[categoria]` contra
`Dim_Categorias[nombre_categoria]`, para modelar la relacion por clave numerica
y no por texto. Una PK de texto es fragil: una diferencia de tilde, espacio o
mayuscula rompe el join en silencio.

## Dim_Fechas

Creada con `CALENDARAUTO()`, que cubre 2022-2024 porque toma el rango completo
de todas las columnas de fecha del modelo (`fecha_venta` y `fecha_registro`).

Columnas calculadas: `Año`, `NroMes`, `Mes Nombre`, `Trimestre`.

`Mes Nombre` esta ordenada por `NroMes` (Ordenar por columna). Sin eso los meses
salen alfabeticos (abril, agosto, diciembre...) en cualquier eje o matriz.

La tabla esta marcada como tabla de fechas sobre la columna `Date`. Es
obligatorio: sin ese paso `TOTALYTD` y `SAMEPERIODLASTYEAR` no funcionan aunque
la formula este bien escrita.

## Tabla _Medidas

Tabla creada con "Introducir datos" y vaciada despues (se elimino `Columna1`),
asi queda con el icono de calculadora y agrupa las cinco medidas sin mezclarlas
con tablas de datos.

## Medidas

```dax
Total Ventas = SUM(Fact_Ventas[total_venta])
```

```dax
Ventas Online = CALCULATE([Total Ventas], Fact_Ventas[canal] = "Online")
```

```dax
Ventas YTD = TOTALYTD([Total Ventas], Dim_Fechas[Date])
```

```dax
Ventas LY = CALCULATE([Total Ventas], SAMEPERIODLASTYEAR(Dim_Fechas[Date]))
```

```dax
% Crecimiento Anual =
VAR VentasActuales = [Total Ventas]
VAR VentasAnioAnterior = [Ventas LY]
VAR Diferencia = VentasActuales - VentasAnioAnterior
RETURN
DIVIDE(Diferencia, VentasAnioAnterior)
```

`% Crecimiento Anual` usa `VAR` para no recalcular `[Ventas LY]` dos veces (una
en la resta y otra en el divisor) y `DIVIDE` en vez de `/` para que un
denominador cero devuelva BLANK en lugar de error. Formateada como porcentaje.

## Validacion

Pagina `Validación`: matriz con `Mes Nombre` en filas, `Año` en columnas y las
cuatro medidas en valores.

| Que se verifica | Resultado |
|---|---|
| Ventas YTD en enero 2023 | 2.967,50 = Total Ventas de enero |
| Ventas YTD en febrero 2023 | 4.984,50 = enero + febrero |
| Ventas LY en 2024 | Muestra los valores de 2023 |
| Ventas LY en 2023 | BLANK: no hay 2022 con ventas |
| % Crecimiento Anual 2024 | -34,59 % sobre el total |

Totales: 2023 = 28.764,00 | 2024 = 18.814,00 | General = 47.578,00

2024 solo tiene ventas hasta julio, por eso de agosto en adelante Total Ventas
queda vacio y el crecimiento da -100 %: el año anterior si tenia ventas en esos
meses. Es el comportamiento esperado, no un error del modelo.
