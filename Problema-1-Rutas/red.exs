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

  # Búsqueda recursiva de itinerarios simples

  # Encuentra recursivamente todos los itinerarios simples entre origen y destino.
  # Un centro no puede repetirse en un mismo itinerario.
  def buscar_itinerarios(grafo, origen, destino) do
    explorar(grafo, origen, destino, [origen], 0, 0)
  end

  # Caso base: cuando el centro actual es el destino, se devuelve el %Itinerario{}.
  defp explorar(_grafo, destino, destino, visitados, minutos, costo) do
    [
      %Itinerario{
        centros: Enum.reverse(visitados),
        minutos: minutos,
        costo: costo
      }
    ]
  end

  # Caso recursivo: recorre los tramos que salen del centro actual hacia centros no visitados.
  defp explorar(grafo, actual, destino, visitados, minutos, costo) do
    tramos_salientes = Map.get(grafo, actual, [])
    explorar_tramos(tramos_salientes, grafo, destino, visitados, minutos, costo)
  end

  defp explorar_tramos([], _grafo, _destino, _visitados, _minutos, _costo), do: []

  defp explorar_tramos([tramo | resto], grafo, destino, visitados, minutos, costo) do
    itinerarios_actual =
      if tramo.destino in visitados do
        []
      else
        explorar(
          grafo,
          tramo.destino,
          destino,
          [tramo.destino | visitados],
          minutos + tramo.minutos,
          costo + tramo.costo
        )
      end

    itinerarios_actual ++ explorar_tramos(resto, grafo, destino, visitados, minutos, costo)
  end

  # Retorna los índices (1..N) de los itinerarios que minimizan la función criterio,
  # conservando todos los empates.
  def minimos([], _criterio), do: []

  def minimos(itinerarios, criterio) do
    valor_minimo =
      itinerarios
      |> Enum.map(criterio)
      |> Enum.min()

    itinerarios
    |> Enum.with_index(1)
    |> Enum.filter(fn {itinerario, _indice} -> criterio.(itinerario) == valor_minimo end)
    |> Enum.map(fn {_itinerario, indice} -> indice end)
  end
end
