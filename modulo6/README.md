# Modulo 6 - Pipeline ETL con Power Query y M

Entregable: Pipeline_ETL_Caiguaraico_Pablo.pbix
Fuente de datos: Pipeline_ETL_Dataset.xlsx (provisto por el curso)
Autor: Pablo Caiguaraico

## Conteo de filas al cerrar y aplicar

- Dim_Clientes: 11 filas (12 originales menos 1 duplicado)
- Dim_Productos: 12 filas (13 originales menos 1 duplicado)
- Dim_Categorias: 4 filas
- Fact_Ventas: 50 filas, mas 2 columnas traidas por el merge

Ninguna consulta quedo con icono de error.

## Decisiones tecnicas sobre los nulos

Dim_Clientes, email nulo (id_cliente 9, Valentina Paz). Se reemplaza por
sin_email@techstore.com y no se elimina la fila. El email es un dato de
contacto, no una clave ni una metrica: su ausencia no invalida al cliente.
Ademas ese cliente tiene ventas registradas, asi que borrarlo dejaria esas
ventas sin dimension asociada y el total por cliente no cuadraria con el
total general.

Dim_Clientes, ciudad nula (id_cliente 11, Roberto Diaz). Se reemplaza por
"Sin datos" en vez de eliminar. Si quedara en null, cualquier grafico
agrupado por ciudad omitiria silenciosamente a ese cliente y el total
geografico no cuadraria con el total general. Con una etiqueta explicita el
faltante queda visible en el reporte.

Dim_Productos, precio nulo (id_producto 109, SSD Externo 1TB). Se imputa con
130 y no se elimina. Es el caso critico del ejercicio: ese producto tiene
ventas reales en la tabla de hechos, por lo que eliminarlo dejaria filas
huerfanas y el total facturado bajaria sin explicacion. El valor no es
inventado: 130 es el precio unitario con el que ese mismo producto ya fue
vendido en la venta 1009, y es coherente con su costo registrado de 75.
Recuperar el dato desde la propia transaccion es preferible a borrar
informacion valida.

Dim_Productos, categoria nula (id_producto 111, Laptop Gaming Pro). Se imputa
con Computacion y no se marca como "Sin Categoria". La fila si trae
subcategoria igual a Laptops, y todos los demas productos con esa
subcategoria pertenecen a Computacion. Imputar con el dato derivado es
preferible a crear una categoria basura que despues ensuciaria los graficos
agrupados por categoria.


## Filas de relleno vacias

El archivo Excel trae filas vacias al final de cada hoja (llega a 999 filas por
hoja). Sin filtrarlas, Power BI las carga como filas en blanco y los conteos no
cuadran. En cada consulta se agrego un paso Filas_vacias_quitadas que filtra
por la clave primaria correspondiente.

## Transformaciones aplicadas

- Encabezados promovidos en las 4 consultas.
- Duplicados eliminados con Table.Distinct sobre la columna de ID, no sobre la
  fila completa: si el duplicado llegara con alguna celda distinta, comparar la
    fila entera no lo detectaria y la PK quedaria repetida, degradando la
      relacion 1:N a muchos-a-muchos.
      - Tipado explicito: IDs y cantidades como entero; precio, costo, descuento y
        total_venta como decimal, porque como entero se perderian los centavos;
          fechas con locale es-ES, ya que el archivo trae formato dia/mes/anio y sin
            el locale 10/07/2022 se leeria como 7 de octubre en vez de 10 de julio.
            - Nomenclatura Dim_ y Fact_ en las 4 consultas.
            - Merge de Fact_Ventas contra Dim_Productos por id_producto con LeftOuter,
              expandiendo solo nombre_producto y categoria. Se usa LeftOuter y no Inner
                para que, si algun id_producto no existiera en la dimension, la venta se
                  conserve y el faltante quede visible como null en vez de desaparecer del
                    total facturado sin dejar rastro.
                    - Fact_Ventas no lleva quitar duplicados: dos ventas distintas pueden coincidir
                      en cliente, producto, fecha y monto y aun asi ser transacciones reales. La
                        unicidad la garantiza id_venta, no la fila completa.

                        ## Documentacion en lenguaje M

                        Las 4 consultas tienen los pasos renombrados con nombres descriptivos y
                        comentarios con // en el Editor Avanzado, explicando el razonamiento de cada
                        decision y no lo obvio.
                        
