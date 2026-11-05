# Integrante: Juan Manuel Rojas
# Integrante: Luisa Fernanda Salazar
#
# Descripción: Archivo principal del Problema 1 (Rutas de entrega en una red dirigida).
# Carga todos los módulos y orquesta el flujo completo mediante funciones pequeñas:
# lectura en flujo -> validación recursiva -> grafo -> consultas -> reportes.

Code.require_file("Util2.ex", __DIR__)
Code.require_file("tramo.exs", __DIR__)
Code.require_file("itinerario.exs", __DIR__)
Code.require_file("validacion.exs", __DIR__)
Code.require_file("red.exs", __DIR__)
Code.require_file("reportes.exs", __DIR__)

defmodule Main do
  def main do
    {carpeta_entradas, carpeta_salidas} = obtener_carpetas()
    ruta_tramos = Path.join(carpeta_entradas, "tramos.csv")
    ruta_consultas = Path.join(carpeta_entradas, "consultas.txt")

    case verificar_archivos([ruta_tramos, ruta_consultas]) do
      :ok -> ejecutar(ruta_tramos, ruta_consultas, carpeta_salidas)
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

  # Orquesta los pasos principales del problema.
  defp ejecutar(ruta_tramos, ruta_consultas, carpeta_salidas) do
    {tramos_validos, errores} = cargar_tramos(ruta_tramos)
    Reportes.guardar_errores_tramos(Path.join(carpeta_salidas, "errores_tramos.txt"), errores)

    {tramos_depurados, descartados} = Validacion.depurar_tramos(tramos_validos)
    Reportes.guardar_depuracion(Path.join(carpeta_salidas, "depuracion_tramos.txt"), descartados)

    grafo = Red.construir_grafo(tramos_depurados)
    centros = Red.obtener_centros(tramos_validos)

    procesar_consultas(ruta_consultas, grafo, centros, carpeta_salidas)
  end

  # Lectura en flujo con Streams

  # Lee un archivo línea por línea con File.stream!/1 ignorando vacías y comentarios (#).
  defp leer_lineas_stream(ruta) do
    ruta
    |> File.stream!()
    |> Stream.with_index(1)
    |> Stream.map(fn {linea, num} -> {num, String.trim(linea)} end)
    |> Stream.reject(&linea_ignorable?/1)
    |> Stream.reject(&encabezado_tramos?/1)
  end

  defp linea_ignorable?({_num, texto}) do
    texto == "" or String.starts_with?(texto, "#")
  end

  defp encabezado_tramos?({_num, texto}) do
    String.downcase(String.replace(texto, " ", "")) == "origen,destino,minutos,costo"
  end

  # Convierte perezosamente cada línea de tramos.csv y separa válidos de errores.
  defp cargar_tramos(ruta_tramos) do
    resultados =
      ruta_tramos
      |> leer_lineas_stream()
      |> Stream.map(fn {num, texto} -> {num, texto, Tramo.parse({num, texto})} end)
      |> Enum.to_list()

    validos = for {_n, _t, {:ok, tramo}} <- resultados, do: tramo
    errores = for {n, t, {:error, motivo}} <- resultados, do: {n, t, motivo}
    {validos, errores}
  end

  # Verificación recursiva de archivos de entrada

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
