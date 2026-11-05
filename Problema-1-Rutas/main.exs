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

  # Procesamiento de consultas

  defp procesar_consultas(ruta_consultas, grafo, centros, carpeta_salidas) do
    ruta_it = Path.join(carpeta_salidas, "itinerarios.txt")
    ruta_alc = Path.join(carpeta_salidas, "alcance_centros.txt")

    Reportes.limpiar_archivo(ruta_it)
    Reportes.limpiar_archivo(ruta_alc)

    ruta_consultas
    |> leer_lineas_stream()
    |> Stream.map(&parsear_consulta/1)
    |> Enum.each(fn consulta ->
      atender_consulta(consulta, grafo, centros, ruta_it, ruta_alc)
    end)
  end

  defp parsear_consulta({linea, texto}) do
    case texto |> String.split(",") |> Enum.map(&String.trim/1) do
      [origen, destino] when origen != "" and destino != "" -> {:ok, {origen, destino}}
      _ -> {:error, linea, texto}
    end
  end

  defp atender_consulta({:error, linea, texto}, _grafo, _centros, ruta_it, _ruta_alc) do
    Reportes.registrar_consulta_invalida(ruta_it, linea, texto)
  end

  defp atender_consulta({:ok, pareja}, grafo, centros, ruta_it, ruta_alc) do
    case verificar_centros_consulta(pareja, centros) do
      :ok -> buscar_y_registrar(pareja, grafo, ruta_it, ruta_alc)
      {:error, centro_faltante} -> Reportes.registrar_centro_inexistente(ruta_it, ruta_alc, pareja, centro_faltante)
    end
  end

  defp verificar_centros_consulta({origen, destino}, centros) do
    cond do
      not MapSet.member?(centros, origen) -> {:error, origen}
      not MapSet.member?(centros, destino) -> {:error, destino}
      true -> :ok
    end
  end

  defp buscar_y_registrar({origen, destino} = pareja, grafo, ruta_it, ruta_alc) do
    {_estados, _paso, alcanzados} = resultado_alcance = Red.calcular_alcance(grafo, origen)
    alcanzable? = MapSet.member?(alcanzados, destino)

    Reportes.registrar_alcance(ruta_alc, pareja, resultado_alcance, alcanzable?)
    registrar_resultado_busqueda(alcanzable?, pareja, grafo, ruta_it)
  end

  defp registrar_resultado_busqueda(true, {origen, destino} = pareja, grafo, ruta_it) do
    itinerarios = Red.buscar_itinerarios(grafo, origen, destino)
    Reportes.registrar_itinerarios(ruta_it, pareja, itinerarios)
  end

  defp registrar_resultado_busqueda(false, pareja, _grafo, ruta_it) do
    Reportes.registrar_sin_itinerarios(ruta_it, pareja)
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

Main.main()
