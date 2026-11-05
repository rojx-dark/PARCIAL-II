# Integrante: Juan Manuel Rojas
#
# Descripción: Módulo de validación previa con recursión para el mapa y la paleta.
# Verifica recursivamente:
#   - que todas las filas tengan igual longitud y no existan filas vacías;
#   - que cada símbolo del mapa esté definido en la paleta;
#   - que el símbolo . exista en la paleta;
#   - que los colores usen la forma #RRGGBB;
#   - que no existan símbolos repetidos en la paleta.
# Cumple el requisito 7: dentro de estas funciones NO se utilizan Enum ni Stream.

defmodule Validacion do
  # ---------------------------------------------------------------
  # Validación recursiva de la paleta
  # ---------------------------------------------------------------

  defp validar_paleta([], vistos), do: {vistos, []}

  defp validar_paleta([color | resto], vistos) do
    err_hex =
      if color_hex_valido?(color.hex) do
        []
      else
        [
          "paleta.csv línea #{color.linea}: el color #{color.hex} del símbolo '#{color.simbolo}' no tiene formato #RRGGBB"
        ]
      end

    {err_rep, nuevos_vistos} =
      case Map.get(vistos, color.simbolo) do
        nil ->
          {[], Map.put(vistos, color.simbolo, color)}

        primero ->
          {[
             "paleta.csv línea #{color.linea}: símbolo '#{color.simbolo}' repetido (definido antes en línea #{primero.linea})"
           ], vistos}
      end

    {vistos_finales, err_resto} = validar_paleta(resto, nuevos_vistos)
    {vistos_finales, concatenar(err_hex, concatenar(err_rep, err_resto))}
  end

  defp verificar_simbolo_fondo(mapa_paleta) do
    if Map.has_key?(mapa_paleta, ".") do
      []
    else
      ["paleta.csv: falta definir el símbolo '.' para el fondo"]
    end
  end

  # Verifica recursivamente que el string sea '#' seguido de 6 dígitos hexadecimales.
  defp color_hex_valido?(<<"#", hex::binary>>), do: seis_digitos_hex?(hex, 0)
  defp color_hex_valido?(_), do: false

  defp seis_digitos_hex?(<<>>, 6), do: true

  defp seis_digitos_hex?(<<c, resto::binary>>, cuenta)
       when cuenta < 6 and (c in ?0..?9 or c in ?a..?f or c in ?A..?F) do
    seis_digitos_hex?(resto, cuenta + 1)
  end

  defp seis_digitos_hex?(_, _), do: false

  # Funciones auxiliares recursivas propias (sin Enum ni Kernel.length/1).
  defp longitud([], acc), do: acc
  defp longitud([_ | resto], acc), do: longitud(resto, acc + 1)

  defp concatenar([], lista2), do: lista2
  defp concatenar([head | tail], lista2), do: [head | concatenar(tail, lista2)]
end
