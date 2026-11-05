# Integrantes: Juan Manuel Rojas, Luisa Fernanda Salazar
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
  # Retorna la lista con todos los problemas encontrados en la paleta y el mapa.
  def validar(filas_mapa, colores_paleta) do
    {mapa_paleta, errores_paleta} = validar_paleta(colores_paleta, %{})
    errores_punto = verificar_simbolo_fondo(mapa_paleta)
    errores_mapa = validar_mapa(filas_mapa, mapa_paleta)

    concatenar(errores_paleta, concatenar(errores_punto, errores_mapa))
  end

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

  # ---------------------------------------------------------------
  # Validación recursiva del mapa
  # ---------------------------------------------------------------

  defp validar_mapa([], _mapa_paleta) do
    ["mapa.txt: el mapa está vacío (no contiene filas)"]
  end

  defp validar_mapa([{_linea, primera_fila} | _] = filas, mapa_paleta) do
    ancho_esperado = longitud(primera_fila, 0)
    validar_filas(filas, 0, ancho_esperado, mapa_paleta)
  end

  defp validar_filas([], _fila_idx, _ancho_esperado, _mapa_paleta), do: []

  defp validar_filas([{linea, simbolos} | resto], fila_idx, ancho_esperado, mapa_paleta) do
    ancho = longitud(simbolos, 0)

    err_longitud =
      cond do
        ancho == 0 ->
          ["mapa.txt línea #{linea} (fila #{fila_idx}): la fila está vacía"]

        ancho != ancho_esperado ->
          [
            "mapa.txt línea #{linea} (fila #{fila_idx}): tiene #{ancho} columnas pero se esperaban #{ancho_esperado}"
          ]

        true ->
          []
      end

    err_simbolos = validar_simbolos_fila(simbolos, linea, fila_idx, 0, mapa_paleta)
    err_resto = validar_filas(resto, fila_idx + 1, ancho_esperado, mapa_paleta)

    concatenar(err_longitud, concatenar(err_simbolos, err_resto))
  end

  defp validar_simbolos_fila([], _linea, _fila, _col, _mapa_paleta), do: []

  defp validar_simbolos_fila([simbolo | resto], linea, fila, col, mapa_paleta) do
     siguientes = validar_simbolos_fila(resto, linea, fila, col + 1, mapa_paleta)

    if Map.has_key?(mapa_paleta, simbolo) do
      siguientes
    else
      [
        "mapa.txt línea #{linea} (fila #{fila}, columna #{col}): símbolo '#{simbolo}' no definido en la paleta"
        | siguientes
      ]
    end
  end

  # Funciones auxiliares recursivas propias (sin Enum ni Kernel.length/1).
  defp longitud([], acc), do: acc
  defp longitud([_ | resto], acc), do: longitud(resto, acc + 1)

  defp concatenar([], lista2), do: lista2
  defp concatenar([head | tail], lista2), do: [head | concatenar(tail, lista2)]
end
