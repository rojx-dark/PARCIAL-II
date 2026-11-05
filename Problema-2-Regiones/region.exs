# Integrantes: Juan Manuel Rojas, Luisa Fernanda Salazar
#
# Descripción: Define la estructura %Region{simbolo, celdas, area, perimetro}
# solicitada en el enunciado, junto con su ID y su caja envolvente {desde, hasta}.

defmodule Region do
  defstruct id: 0, simbolo: "", celdas: [], area: 0, perimetro: 0, desde: {0, 0}, hasta: {0, 0}

  # Convierte una región a una línea CSV usando ; como separador:
  # id;simbolo;area;perimetro;desde;hasta
  def a_csv(%Region{
        id: id,
        simbolo: simbolo,
        area: area,
        perimetro: perimetro,
        desde: {f_min, c_min},
        hasta: {f_max, c_max}
      }) do
    "#{id};#{simbolo};#{area};#{perimetro};{#{f_min},#{c_min}};{#{f_max},#{c_max}}\n"
  end
end
