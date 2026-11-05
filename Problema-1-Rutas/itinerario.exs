# Integrante: Juan Manuel Rojas
# Integrante: Luisa Fernanda Salazar
#
# Descripción: Define la estructura %Itinerario{centros, minutos, costo}
# solicitada en el enunciado para representar cada recorrido simple encontrado.

defmodule Itinerario do
  defstruct centros: [], minutos: 0, costo: 0

  # La cantidad de tramos utilizados en el itinerario es la cantidad de centros menos 1.
  def cantidad_tramos(%Itinerario{centros: centros}) do
    max(length(centros) - 1, 0)
  end

  # Formatea el itinerario como: A → B → D | tramos: 2 | 15 min | costo: 9
  def formatear(%Itinerario{centros: centros, minutos: minutos, costo: costo} = itinerario) do
    ruta = Enum.join(centros, " → ")
    tramos = cantidad_tramos(itinerario)
    "#{ruta} | tramos: #{tramos} | #{minutos} min | costo: #{costo}"
  end
end
