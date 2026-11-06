# Parcial 2 - Programación III (G2N)

**Universidad del Quindío**  
**Programa de Ingeniería de Sistemas y Computación**  
**Docente:** Julián Esteban Gutiérrez Posada  
**Integrante:** Juan Manuel Rojas  
**Integrante:** Luisa Fernanda Salazar

Soluciones en Elixir a los problemas elegidos del Parcial 2:
- **Problema 1:** Rutas de entrega en una red dirigida (`Problema1-Rutas/`)
- **Problema 2:** Identificación de regiones en un mapa de colores y exportación SVG (`Problema2-Regiones/`)

---

## Organización de cada problema

Cada carpeta de problema está clasificada en tres directorios concretos:
- `entradas/`: archivos de entrada principales del problema.
- `salidas/`: archivos de salida generados por flujo al ejecutar el programa.
- `pruebas/`: pruebas realizadas (`caso_valido/`, `caso_invalido/` y `caso_limite/`), cada una con su propia subcarpeta `entradas/` y `salidas/`.

---

## Instrucciones de ejecución

### 1. Problema 1: Rutas de entrega en una red dirigida

Ubicarse en la carpeta `Problema1-Rutas` y ejecutar `main.exs`:

```bash
cd Problema1-Rutas
elixir main.exs
```

- Lee de `entradas/`: `tramos.csv` y `consultas.txt`.
- Escribe por flujo en `salidas/`: `errores_tramos.txt`, `depuracion_tramos.txt`, `alcance_centros.txt` e `itinerarios.txt`.

Para ejecutar cualquiera de las pruebas realizadas:
```bash
elixir main.exs pruebas/caso_valido
elixir main.exs pruebas/caso_invalido
elixir main.exs pruebas/caso_limite
```

---

### 2. Problema 2: Identificación de regiones en un mapa de colores y exportación SVG

Ubicarse en la carpeta `Problema2-Regiones` y ejecutar `main.exs`:

```bash
cd Problema2-Regiones
elixir main.exs
```

- Lee de `entradas/`: `mapa.txt` y `paleta.csv`.
- Escribe por flujo en `salidas/`: `validacion_mapa.txt`, `regiones.csv`, `resumen_regiones.txt` y `mapa_regiones.svg` (abre directamente en cualquier navegador web).

Para ejecutar cualquiera de las pruebas realizadas:
```bash
elixir main.exs pruebas/caso_valido
elixir main.exs pruebas/caso_invalido
elixir main.exs pruebas/caso_limite
```