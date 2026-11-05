# Integrante: Juan Manuel Rojas
# Integrante: Luisa Fernanda Salazar
#
# Descripción: Define la estructura %Tramo{origen, destino, minutos, costo}
# y la función Tramo.parse/1 que convierte una línea de tramos.csv en
# {:ok, tramo} o {:error, motivo}. También guarda el número de línea
# física original en el struct para la validación previa.

defmodule Tramo do
  defstruct origen: "", destino: "", minutos: 0, costo: 0, linea: 0, contenido: ""

  # Recibe una línea como texto o como tupla {numero_linea, texto}
  # y retorna {:ok, %Tramo{}} o {:error, motivo}.
  def parse({linea, texto}) do
    case parse(texto) do
      {:ok, tramo} -> {:ok, %Tramo{tramo | linea: linea, contenido: texto}}
      {:error, motivo} -> {:error, motivo}
    end
  end

  def parse(texto) do
    campos =
      texto
      |> String.split(",")
      |> Enum.map(&String.trim/1)

    with {:ok, [origen, destino, min_txt, costo_txt]} <- validar_cantidad_campos(campos),
         {:ok, origen} <- validar_centro(origen, "origen"),
         {:ok, destino} <- validar_centro(destino, "destino"),
         {:ok, minutos} <- validar_entero_positivo(min_txt, "minutos"),
         {:ok, costo} <- validar_entero_positivo(costo_txt, "costo") do
      {:ok,
       %Tramo{
         origen: origen,
         destino: destino,
         minutos: minutos,
         costo: costo,
         contenido: texto
       }}
    end
  end

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
