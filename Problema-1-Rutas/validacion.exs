# Integrante: Juan Manuel Rojas
# Integrante: Luisa Fernanda Salazar
#
# Descripción: Módulo de validación previa con recursión para depurar la red.
# Recorre recursivamente los tramos válidos y descarta:
#   - los tramos que salen y llegan al mismo centro (bucle);
#   - las repeticiones de la misma pareja origen -> destino en la misma dirección,
#     conservando siempre la primera aparición.
# Cumple el requisito 7: dentro de estas funciones NO se utilizan Enum ni Stream.

defmodule Validacion do
  # Recibe la lista de %Tramo{} válidos y retorna {tramos_depurados, descartados},
  # donde cada elemento de descartados es {tramo, motivo}.
  def depurar_tramos(tramos) do
    depurar_recursivo(tramos, %{}, [], [])
  end

  # Caso base: cuando se termina la lista, se invierten los acumuladores recursivamente.
  defp depurar_recursivo([], _vistos, validos_acc, descartados_acc) do
    {invertir(validos_acc, []), invertir(descartados_acc, [])}
  end

  # Caso 1: el tramo sale y llega al mismo centro.
  defp depurar_recursivo(
         [%Tramo{origen: mismo, destino: mismo} = tramo | tail],
         vistos,
         validos_acc,
         descartados_acc
       ) do
    motivo = "sale y llega al mismo centro (#{mismo})"
    depurar_recursivo(tail, vistos, validos_acc, [{tramo, motivo} | descartados_acc])
  end

  # Caso 2: se verifica si la pareja {origen, destino} ya apareció antes.
  defp depurar_recursivo([tramo | tail], vistos, validos_acc, descartados_acc) do
    pareja = {tramo.origen, tramo.destino}

    case Map.get(vistos, pareja) do
      nil ->
        nuevos_vistos = Map.put(vistos, pareja, tramo)
        depurar_recursivo(tail, nuevos_vistos, [tramo | validos_acc], descartados_acc)

      primero ->
        motivo =
          "repetición de la pareja #{tramo.origen},#{tramo.destino} (se conserva la de la línea #{primero.linea})"

        depurar_recursivo(tail, vistos, validos_acc, [{tramo, motivo} | descartados_acc])
    end
  end

  # Función auxiliar recursiva propia para invertir una lista sin usar Enum.
  defp invertir([], acc), do: acc
  defp invertir([head | tail], acc), do: invertir(tail, [head | acc])
end
