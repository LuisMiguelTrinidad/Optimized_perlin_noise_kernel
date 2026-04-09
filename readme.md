# Implementación de un kernel de ruido perlin optimizado

Implementación y benchmark de ruido Perlin en Zig con cinco variantes de optimización: O0, O1, O2, O3 y O4.

## Requisitos

- Zig 0.15.2
- Recomendado para mejores resultados SIMD:
  - AVX2 o AVX512BW en x86_64
  - NEON en aarch64

## Compilación y ejecución

Desde esta carpeta:

```bash
zig build --release=fast
./zig-out/bin/perlin O3
```

También puedes ejecutar con:

```bash
zig build --release=fast run -- O4
```

Para obtener métricas precisas has de desactivar la variabilidad de frecuencias y ajustar las frecuencias en config.zig

## Modos disponibles

- O0: implementación de referencia (f32), cálculo directo por muestra.
- O1: variante tiling (f32) con tablas precalculadas de coordenadas y smoothstep.
- O2: variante LICM (f32) con reducción de recomputación en interpolaciones internas.
- O3: variante vectorizada (f32) basada en SIMD.
- O4: variante vectorizada en punto fijo i16 (Q0.15).

Nota: O0..O4 son nombres de variantes del algoritmo, no flags del compilador Zig.

## Estructura real del proyecto

```text
src/
  main.zig
  root.zig

  benchmark/
    config.zig
    engine.zig
    runner.zig
    report.zig
    f32/
      run_mode.zig
      image_writer.zig
    i16/
      run_mode.zig
      image_writer.zig
    image/
      composite_builder.zig
      output_naming.zig
      png_writer.zig
      types.zig

  core/
    shared/
      arch_caps.zig
      cycle_counter.zig
      hash.zig
      math.zig
    f32/
      table.zig
      vector_math.zig
    i16/
      table.zig
      vector_math.zig

  noise/perlin/
    mode_meta.zig
    00_ref.zig
    01_tiling.zig
    02_licm.zig
    03_simd.zig
    04_fpa.zig
    registry.zig
```

## Salida

Cada ejecución produce:

- reporte de rendimiento en consola (Mpts/s y ciclos/punto)
- imagen PNG en output/perlin_composite_*_zig_<modo>.png

## Restricciones

### Obligatorias

- SCALE debe ser potencia de 2 y mayor que 0.
- O3 y O4 validan en comptime que min(CHUNK_SIZE, SCALE) sea múltiplo de LANES.
- O3 y O4 validan alineación de coordenadas world_x/world_y respecto al ancho vectorial.

### Recomendadas

- Para comparaciones estables de benchmark, usar CHUNK_SIZE y SCALE como potencias de 2.
- En i16 (O4), mantener SCALE <= 8192 para evitar problemas de representación Q0.15 en tablas precalculadas.

Distributed under the LGPLv3 License. This ensures that the core optimizations remain open and any improvements made by third parties are contributed back to the community
