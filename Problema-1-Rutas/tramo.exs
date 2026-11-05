# Integrante: Juan Manuel Rojas
# Integrante: Luisa Fernanda Salazar
#
# Descripción: Define la estructura %Tramo{origen, destino, minutos, costo}
# y la función Tramo.parse/1 que convierte una línea de tramos.csv en
# {:ok, tramo} o {:error, motivo}. También guarda el número de línea
# física original en el struct para la validación previa.

defmodule Tramo do
  defstruct origen: "", destino: "", minutos: 0, costo: 0, linea: 0, contenido: ""


  defp validar_cantidad_campos([_, _, _, _] = campos), do: {:ok, campos}

  defp validar_cantidad_campos(_campos),
    do: {:error, "formato inválido: se esperan 4 campos (origen,destino,minutos,costo)"}

  defp validar_centro("", nombre_campo), do: {:error, "#{nombre_campo} vacío"}
  defp validar_centro(centro, _nombre_campo), do: {:ok, centro}

  defp validar_entero_positivo(texto, nombre_campo) do
    case Integer.parse(texto) do
      {valor, ""} when valor > 0 ->
        {:ok, valor}

      {valor, ""} ->
        {:error, "#{nombre_campo} debe ser un entero positivo (recibido: #{valor})"}

      _ ->
        {:error, "#{nombre_campo} no es un entero válido (#{texto})"}
    end
  end

end
