# Integrantes: Juan Manuel Rojas, Luisa Fernanda Salazar
#
# Descripción: Archivo principal del Problema 2 (Identificación de regiones en un
# mapa de colores y exportación SVG).
# Carga todos los módulos y orquesta el flujo completo mediante funciones pequeñas:
# lectura en flujo -> validación recursiva -> identificación de regiones -> reportes y SVG.

Code.require_file("Util2.ex", __DIR__)
Code.require_file("color.exs", __DIR__)
Code.require_file("region.exs", __DIR__)
Code.require_file("validacion.exs", __DIR__)
Code.require_file("regiones.exs", __DIR__)
Code.require_file("reportes.exs", __DIR__)

defmodule Main do
  def main do
    {carpeta_entradas, carpeta_salidas} = obtener_carpetas()
    ruta_mapa = Path.join(carpeta_entradas, "mapa.txt")
    ruta_paleta = Path.join(carpeta_entradas, "paleta.csv")

    case verificar_archivos([ruta_mapa, ruta_paleta]) do
      :ok -> ejecutar(ruta_mapa, ruta_paleta, carpeta_salidas)
      {:error, faltantes} -> mostrar_faltantes(faltantes)
    end
  end

  # Determina las carpetas de entrada y salida según el argumento opcional.
  defp obtener_carpetas do
    base =
      case System.argv() do
        [ruta | _] -> Path.expand(ruta, __DIR__)
        [] -> __DIR__
      end

    salidas = Path.join(base, "salidas")
    File.mkdir_p!(salidas)
    {Path.join(base, "entradas"), salidas}
  end

  # Orquesta la carga, la validación recursiva y el cálculo de regiones.
  defp ejecutar(ruta_mapa, ruta_paleta, carpeta_salidas) do
    filas_mapa = cargar_mapa(ruta_mapa)
    {colores_paleta, errores_formato} = cargar_paleta(ruta_paleta)

    errores = errores_formato ++ Validacion.validar(filas_mapa, colores_paleta)
    Reportes.guardar_validacion(Path.join(carpeta_salidas, "validacion_mapa.txt"), errores)

    responder_validacion(errores, filas_mapa, colores_paleta, carpeta_salidas)
  end

  defp responder_validacion([], filas_mapa, colores_paleta, carpeta_salidas) do
    mapa = Regiones.construir_mapa(filas_mapa)
    paleta = Map.new(colores_paleta, fn color -> {color.simbolo, color} end)
    regiones = Regiones.identificar_regiones(mapa)

    generar_salidas(carpeta_salidas, mapa, regiones, paleta)
  end

  defp responder_validacion(errores, _filas_mapa, _colores_paleta, _carpeta_salidas) do
    Util2.mostrar("Se encontraron errores en la validación (ver salidas/validacion_mapa.txt):", :error)
    Enum.each(errores, fn err -> Util2.mostrar("  - #{err}", :error) end)
  end

  defp generar_salidas(carpeta_salidas, mapa, regiones, paleta) do
    Reportes.guardar_regiones_csv(Path.join(carpeta_salidas, "regiones.csv"), regiones)
    Reportes.mostrar_y_guardar_resumen(Path.join(carpeta_salidas, "resumen_regiones.txt"), regiones)
    Reportes.guardar_svg(Path.join(carpeta_salidas, "mapa_regiones.svg"), mapa, regiones, paleta)
  end

  # ---------------------------------------------------------------
  # Lectura en flujo con Streams
  # ---------------------------------------------------------------

  defp leer_lineas_stream(ruta) do
    ruta
    |> File.stream!()
    |> Stream.with_index(1)
    |> Stream.map(fn {linea, num} -> {num, String.trim(linea)} end)
    |> Stream.reject(&linea_ignorable?/1)
  end

  defp linea_ignorable?({_num, texto}) do
    texto == "" or String.starts_with?(texto, "#")
  end

  defp cargar_mapa(ruta_mapa) do
    ruta_mapa
    |> leer_lineas_stream()
    |> Stream.map(fn {num, texto} -> {num, String.split(texto)} end)
    |> Enum.to_list()
  end

  defp cargar_paleta(ruta_paleta) do
    resultados =
      ruta_paleta
      |> leer_lineas_stream()
      |> Stream.reject(&encabezado_paleta?/1)
      |> Stream.map(&Color.parse/1)
      |> Enum.to_list()

    colores = for {:ok, color} <- resultados, do: color
    errores = for {:error, motivo} <- resultados, do: motivo
    {colores, errores}
  end

  defp encabezado_paleta?({_num, texto}) do
    String.downcase(String.replace(texto, " ", "")) == "simbolo,nombre,color_hex"
  end

  # ---------------------------------------------------------------
  # Verificación recursiva de archivos de entrada
  # ---------------------------------------------------------------

  defp verificar_archivos(rutas) do
    case buscar_faltantes(rutas) do
      [] -> :ok
      faltantes -> {:error, faltantes}
    end
  end

  defp buscar_faltantes([]), do: []

  defp buscar_faltantes([ruta | resto]) do
    if File.exists?(ruta), do: buscar_faltantes(resto), else: [ruta | buscar_faltantes(resto)]
  end

  defp mostrar_faltantes(faltantes) do
    Enum.each(faltantes, fn ruta ->
      Util2.mostrar("Error: falta el archivo requerido #{Path.basename(ruta)}", :error)
    end)
  end
end

Main.main()
