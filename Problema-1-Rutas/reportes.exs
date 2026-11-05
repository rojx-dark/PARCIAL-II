# Integrante: Juan Manuel Rojas
# Integrante: Luisa Fernanda Salazar
#
# Descripción: Módulo encargado de generar los archivos de salida por flujo
# (sin formar un único string en memoria) y mostrar los resúmenes en pantalla.
#   - errores_tramos.txt
#   - depuracion_tramos.txt
#   - alcance_centros.txt
#   - itinerarios.txt

defmodule Reportes do
  # Inicializa o reemplaza un archivo vacío al comenzar la ejecución.
  def limpiar_archivo(ruta) do
    File.write!(ruta, "")
  end

  # Agrega un Stream o lista de líneas al final de un archivo por flujo.
  def agregar_lineas(ruta, lineas) do
    lineas
    |> Stream.into(File.stream!(ruta, [:append]))
    |> Stream.run()
  end

  # Escribe errores_tramos.txt por flujo a partir de la lista de {linea, contenido, motivo}.
  def guardar_errores_tramos(ruta, []) do
    ["Sin errores de formato o datos en tramos.csv.\n"]
    |> Stream.into(File.stream!(ruta))
    |> Stream.run()
  end

  def guardar_errores_tramos(ruta, errores) do
    errores
    |> Stream.map(fn {linea, contenido, motivo} ->
      "Línea #{linea}: #{contenido} -> #{motivo}\n"
    end)
    |> Stream.into(File.stream!(ruta))
    |> Stream.run()
  end

  # Escribe depuracion_tramos.txt por flujo a partir de la lista de {tramo, motivo}.
  def guardar_depuracion(ruta, []) do
    ["Sin tramos descartados en la depuración.\n"]
    |> Stream.into(File.stream!(ruta))
    |> Stream.run()
  end

  def guardar_depuracion(ruta, descartados) do
    descartados
    |> Stream.map(fn {tramo, motivo} ->
      "Línea #{tramo.linea}: #{tramo.contenido} -> #{motivo}\n"
    end)
    |> Stream.into(File.stream!(ruta))
    |> Stream.run()
  end

  # Registra en alcance_centros.txt los pasos del Stream infinito de una consulta.
  def registrar_alcance(ruta_alcance, {origen, destino}, {estados, paso_estable, _alcanzados}, alcanzable?) do
    lineas = lineas_alcance(origen, destino, estados, paso_estable, alcanzable?)
    agregar_lineas(ruta_alcance, lineas)
  end

  # Registra en itinerarios.txt y en pantalla los itinerarios encontrados.
  def registrar_itinerarios(ruta_itinerarios, {origen, destino}, itinerarios) do
    lineas = lineas_itinerarios(origen, destino, itinerarios)
    agregar_lineas(ruta_itinerarios, lineas)
    Util2.mostrar("#{origen} → #{destino}: Total #{length(itinerarios)} itinerarios", :mensaje)
  end

  # Registra en itinerarios.txt y en pantalla cuando el destino no es alcanzable.
  def registrar_sin_itinerarios(ruta_itinerarios, {origen, destino}) do
    agregar_lineas(ruta_itinerarios, ["=== #{origen} → #{destino} ===\n", "sin itinerarios\n\n"])
    Util2.mostrar("#{origen} → #{destino}: sin itinerarios", :mensaje)
  end

  # Registra cuando un centro de la consulta no existe en la red.
  def registrar_centro_inexistente(ruta_it, ruta_alc, {origen, destino}, centro) do
    mensaje = "El centro #{centro} no existe en la red"
    bloque = ["=== #{origen} → #{destino} ===\n", "#{mensaje}\n\n"]

    Util2.mostrar("#{origen} → #{destino}: #{mensaje}", :mensaje)
    agregar_lineas(ruta_it, bloque)
    agregar_lineas(ruta_alc, bloque)
  end

  # Registra cuando una línea de consultas.txt tiene formato inválido.
  def registrar_consulta_invalida(ruta_itinerarios, linea, texto) do
    mensaje = "Consulta inválida en línea #{linea}: #{texto}"
    Util2.mostrar(mensaje, :error)
    agregar_lineas(ruta_itinerarios, [mensaje <> "\n\n"])
  end

  # ---------------------------------------------------------------
  # Construcción perezosa de bloques de texto
  # ---------------------------------------------------------------

  defp lineas_alcance(origen, destino, estados, paso_estable, alcanzable?) do
    encabezado = ["=== #{origen} → #{destino} ===\n"]

    pasos =
      Stream.map(estados, fn {paso, conjunto} ->
        centros = conjunto |> Enum.sort() |> Enum.join(", ")
        "Paso #{paso}: {#{centros}}\n"
      end)

    cierre = [mensaje_estabilizacion(destino, paso_estable, alcanzable?)]
    Stream.concat([encabezado, pasos, cierre])
  end

  defp mensaje_estabilizacion(destino, paso, true) do
    "Se estabiliza en el paso #{paso} (destino #{destino} alcanzable)\n\n"
  end

  defp mensaje_estabilizacion(destino, paso, false) do
    "Se estabiliza en el paso #{paso} (destino #{destino} no alcanzable: sin itinerarios)\n\n"
  end

  defp lineas_itinerarios(origen, destino, itinerarios) do
    encabezado = ["=== #{origen} → #{destino} ===\n"]

    cuerpo =
      itinerarios
      |> Stream.with_index(1)
      |> Stream.map(fn {itinerario, numero} ->
        "Itinerario #{numero}: #{Itinerario.formatear(itinerario)}\n"
      end)

    resumen = [
      "Total: #{length(itinerarios)} itinerarios\n",
      "Menos tramos: #{formatear_minimos(itinerarios, &Itinerario.cantidad_tramos/1)}\n",
      "Menor tiempo: #{formatear_minimos(itinerarios, fn it -> it.minutos end)}\n",
      "Menor costo: #{formatear_minimos(itinerarios, fn it -> it.costo end)}\n\n"
    ]

    Stream.concat([encabezado, cuerpo, resumen])
  end

  defp formatear_minimos(itinerarios, criterio) do
    itinerarios
    |> Red.minimos(criterio)
    |> Enum.join(", ")
  end
end
