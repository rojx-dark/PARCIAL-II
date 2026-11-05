# Integrantes: Juan Manuel Rojas, Luisa Fernanda Salazar
#
# Descripción: Módulo con la representación del mapa y la identificación recursiva
# de regiones conectadas (horizontales o verticales), utilizando:
#   - una función recursiva que recorre las casillas aún no visitadas, y
#   - otra función recursiva que explora los vecinos del mismo símbolo.

defmodule Regiones do
  # Construye la estructura del mapa %{celdas: %{{f, c} => simbolo}, filas: n, columnas: m}
  # después de haber consumido el Stream de lectura.
  def construir_mapa(filas_leidas) do
    celdas =
      filas_leidas
      |> Enum.with_index(0)
      |> Enum.flat_map(fn {{_linea, simbolos}, fila} ->
        simbolos
        |> Enum.with_index(0)
        |> Enum.map(fn {simbolo, col} -> {{fila, col}, simbolo} end)
      end)
      |> Map.new()

    total_filas = length(filas_leidas)

    total_columnas =
      case filas_leidas do
        [{_linea, primera} | _] -> length(primera)
        [] -> 0
      end

    %{celdas: celdas, filas: total_filas, columnas: total_columnas}
  end

  # Encuentra todas las regiones del mapa sin recorrer dos veces una casilla ya asignada.
  # Asigna IDs empezando en 1 según el orden ascendente de filas y columnas.
  def identificar_regiones(mapa) do
    recorrer_casillas(mapa, 0, 0, MapSet.new(), [], 1)
  end

  # 1. Función recursiva que recorre las casillas aún no visitadas en orden (fila, columna).
  defp recorrer_casillas(%{filas: filas}, filas, _col, _visitadas, regiones_acc, _id) do
    Enum.reverse(regiones_acc)
  end

  defp recorrer_casillas(%{columnas: cols} = mapa, fila, cols, visitadas, regiones_acc, id) do
    recorrer_casillas(mapa, fila + 1, 0, visitadas, regiones_acc, id)
  end

  defp recorrer_casillas(mapa, fila, col, visitadas, regiones_acc, id) do
    pos = {fila, col}
    simbolo = Map.get(mapa.celdas, pos)

    if simbolo == "." or MapSet.member?(visitadas, pos) do
      recorrer_casillas(mapa, fila, col + 1, visitadas, regiones_acc, id)
    else
      {celdas_region, nuevas_visitadas} =
        explorar_vecinos([pos], simbolo, mapa, MapSet.put(visitadas, pos), [])

      region = construir_region(id, simbolo, celdas_region, mapa)
      recorrer_casillas(mapa, fila, col + 1, nuevas_visitadas, [region | regiones_acc], id + 1)
    end
  end

  # 2. Función recursiva que explora vecinos horizontales y verticales del mismo símbolo.
  defp explorar_vecinos([], _simbolo, _mapa, visitadas, celdas_acc) do
    {Enum.sort(celdas_acc), visitadas}
  end

  defp explorar_vecinos([actual | pendientes], simbolo, mapa, visitadas, celdas_acc) do
    nuevos_vecinos =
      actual
      |> vecinos_ortogonales()
      |> Enum.filter(fn pos ->
        Map.get(mapa.celdas, pos) == simbolo and not MapSet.member?(visitadas, pos)
      end)

    visitadas_actualizadas =
      Enum.reduce(nuevos_vecinos, visitadas, fn pos, acc -> MapSet.put(acc, pos) end)

    explorar_vecinos(
      nuevos_vecinos ++ pendientes,
      simbolo,
      mapa,
      visitadas_actualizadas,
      [actual | celdas_acc]
    )
  end

  # Vecinos arriba, abajo, izquierda y derecha (las diagonales no unen regiones).
  def vecinos_ortogonales({fila, col}) do
    [{fila - 1, col}, {fila + 1, col}, {fila, col - 1}, {fila, col + 1}]
  end

end
