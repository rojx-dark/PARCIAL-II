# Integrantes: Juan Manuel Rojas, Luisa Fernanda Salazar
#
# Descripción: Define la estructura %Color{simbolo, nombre, hex} solicitada en el
# enunciado para representar cada fila de paleta.csv.

defmodule Color do
  defstruct simbolo: "", nombre: "", hex: "", linea: 0

  # Convierte una tupla {linea, texto} de paleta.csv en {:ok, %Color{}} o {:error, motivo}.
  def parse({linea, texto}) do
    case texto |> String.split(",") |> Enum.map(&String.trim/1) do
      [simbolo, nombre, hex] when simbolo != "" and nombre != "" and hex != "" ->
        {:ok, %Color{simbolo: simbolo, nombre: nombre, hex: hex, linea: linea}}

      _ ->
        {:error, "paleta.csv línea #{linea}: formato inválido (#{texto})"}
    end
  end
end
