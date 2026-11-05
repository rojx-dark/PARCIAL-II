# Integrantes: Juan Manuel Rojas, Luisa Fernanda Salazar
#
# Descripción: Módulo de salida y exportación SVG del Problema 2.
# Genera por fragmentos en flujo (sin concatenar el documento completo en memoria):
#   - validacion_mapa.txt
#   - regiones.csv
#   - resumen_regiones.txt
#   - mapa_regiones.svg (casillas de 40 x 40 px, fondo, bordes y texto con ID de región)

defmodule Reportes do
  @tamano 40

  # Escribe validacion_mapa.txt por flujo.
  def guardar_validacion(ruta, errores) do
    lineas =
      case errores do
        [] -> ["Mapa y paleta válidos: sin errores.\n"]
        _ -> Stream.map(errores, fn error -> "#{error}\n" end)
      end

    lineas
    |> Stream.into(File.stream!(ruta))
    |> Stream.run()
  end

  # Escribe regiones.csv por flujo con el encabezado id;simbolo;area;perimetro;desde;hasta.
  def guardar_regiones_csv(ruta, regiones) do
    encabezado = ["id;simbolo;area;perimetro;desde;hasta\n"]
    filas = Stream.map(regiones, &Region.a_csv/1)

    Stream.concat(encabezado, filas)
    |> Stream.into(File.stream!(ruta))
    |> Stream.run()
  end

  # Construye las líneas del resumen de regiones (total y máximos con empates),
  # las muestra en pantalla y las escribe por flujo en resumen_regiones.txt.
  def mostrar_y_guardar_resumen(ruta, regiones) do
    {max_area, mayores_area} = Regiones.obtener_maximos(regiones, :area)
    {max_perim, mayores_perim} = Regiones.obtener_maximos(regiones, :perimetro)

    lineas = [
      "Total de regiones: #{length(regiones)}",
      formatear_maximos("Mayor área", max_area, mayores_area),
      formatear_maximos("Mayor perímetro", max_perim, mayores_perim)
    ]

    Enum.each(lineas, fn linea -> Util2.mostrar(linea, :mensaje) end)

    lineas
    |> Stream.map(fn linea -> linea <> "\n" end)
    |> Stream.into(File.stream!(ruta))
    |> Stream.run()
  end

  defp formatear_maximos(titulo, _valor, []), do: "#{titulo}: ninguna"

  defp formatear_maximos(titulo, valor, regiones) do
    detalle =
      regiones
      |> Enum.map(fn r -> "región #{r.id} (#{r.simbolo})" end)
      |> Enum.join(", ")

    "#{titulo} (#{valor}): #{detalle}"
  end

  # ---------------------------------------------------------------
  # Exportación progresiva de mapa_regiones.svg por fragmentos
  # ---------------------------------------------------------------

  def guardar_svg(ruta, mapa, regiones, paleta) do
    ancho = mapa.columnas * @tamano
    alto = mapa.filas * @tamano
    color_fondo = Map.fetch!(paleta, ".").hex

    # Mapa de la primera casilla de cada región -> ID de la región
    etiquetas_id =
      Map.new(regiones, fn region ->
        {hd(region.celdas), region.id}
      end)

    apertura = [
      "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"#{ancho}\" height=\"#{alto}\" viewBox=\"0 0 #{ancho} #{alto}\">\n",
      "  <rect x=\"0\" y=\"0\" width=\"#{ancho}\" height=\"#{alto}\" fill=\"#{escapar_xml(color_fondo)}\"/>\n"
    ]

    elementos =
      Stream.flat_map(0..(mapa.filas - 1)//1, fn fila ->
        Stream.map(0..(mapa.columnas - 1)//1, fn col ->
          dibujar_casilla(fila, col, mapa, paleta, etiquetas_id)
        end)
      end)

    cierre = ["</svg>\n"]

    Stream.concat([apertura, elementos, cierre])
    |> Stream.into(File.stream!(ruta))
    |> Stream.run()
  end

  defp dibujar_casilla(fila, col, mapa, paleta, etiquetas_id) do
    pos = {fila, col}
    simbolo = Map.get(mapa.celdas, pos)
    color_hex = Map.fetch!(paleta, simbolo).hex
    px = col * @tamano
    py = fila * @tamano

    rectangulo =
      "  <rect x=\"#{px}\" y=\"#{py}\" width=\"#{@tamano}\" height=\"#{@tamano}\" " <>
        "fill=\"#{escapar_xml(color_hex)}\" stroke=\"#334155\" stroke-width=\"1\"/>\n"

    case Map.get(etiquetas_id, pos) do
      nil ->
        rectangulo

      id ->
        cx = px + div(@tamano, 2)
        cy = py + div(@tamano, 2)
        texto_id = escapar_xml(Integer.to_string(id))

        rectangulo <>
          "  <text x=\"#{cx}\" y=\"#{cy}\" text-anchor=\"middle\" dominant-baseline=\"central\" " <>
          "font-family=\"sans-serif\" font-size=\"14\" font-weight=\"bold\" fill=\"#000000\">#{texto_id}</text>\n"
    end
  end

  # Escapa correctamente cualquier texto que se incorpore al XML.
  def escapar_xml(texto) do
    texto
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end
end
