# Integrante: Juan Manuel Rojas
# Integrante: Luisa Fernanda Salazar
#
# Descripción: Módulo con la construcción del grafo dirigido, el Stream infinito
# de centros alcanzables y la búsqueda recursiva de itinerarios simples.

defmodule Red do
  # Construye el grafo como un mapa %{origen => [tramos]} respetando el orden de aparición.
  def construir_grafo(tramos) do
    Enum.group_by(tramos, fn tramo -> tramo.origen end)
  end

  # Obtiene el conjunto de todos los centros que existen en la red.
  def obtener_centros(tramos) do
    tramos
    |> Enum.flat_map(fn tramo -> [tramo.origen, tramo.destino] end)
    |> MapSet.new()
  end

  # Stream infinito: centros alcanzables

  # Construye un Stream infinito de conjuntos (MapSet) de centros alcanzables:
  #   - paso 0: contiene únicamente el origen
  #   - paso siguiente: añade los destinos de los tramos que salen de los centros ya alcanzados
  def stream_alcanzables(grafo, origen) do
    Stream.iterate(MapSet.new([origen]), fn alcanzados ->
      nuevos_destinos =
        alcanzados
        |> Enum.flat_map(fn centro ->
          grafo
          |> Map.get(centro, [])
          |> Enum.map(fn tramo -> tramo.destino end)
        end)
        |> MapSet.new()

      MapSet.union(alcanzados, nuevos_destinos)
    end)
  end

  # Consume únicamente los pasos necesarios del Stream infinito hasta detectar
  # el primer estado repetido consecutivo.
  # Retorna {estados_distintos, paso_estabilizacion, conjunto_final}.
  def calcular_alcance(grafo, origen) do
    estados_distintos =
      grafo
      |> stream_alcanzables(origen)
      |> Stream.with_index(0)
      |> Stream.transform(nil, fn {conjunto, paso}, anterior ->
        if conjunto == anterior do
          {:halt, anterior}
        else
          {[{paso, conjunto}], conjunto}
        end
      end)
      |> Enum.to_list()

    {paso_estable, conjunto_final} = List.last(estados_distintos)
    {estados_distintos, paso_estable, conjunto_final}
  end
end
