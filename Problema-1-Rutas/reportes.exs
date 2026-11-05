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
end
