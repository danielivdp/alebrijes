# Animales base

Son el "antes" de la mezcla: el animal **normal**, con sus colores naturales y sin patrones de alebrije,
para que el contraste con la mezcla sea evidente.

## Prompt

```text
Use case: illustration-story
Asset type: game card, base animal before being turned into an alebrije
Primary request: a single <animal en inglés>, full body, standing in a clear side or three-quarter view
Subject: one <animal>, natural real-world colors, friendly expression, no decorative patterns
Composition/framing: centered, entire body visible with margin on all sides, square canvas
Background: transparent
<bloque de estilo de estilo.md>
Avoid: extra animals, props, ground, shadows on the floor, decorative patterns
```

## Checklist

| Revisar | Aceptable |
|---|---|
| Un solo animal, cuerpo completo | Nada cortado por el borde |
| Fondo | Transparente de verdad (alpha), no blanco ni cuadriculado pintado |
| Colores | Naturales, planos, sin patrones |
| Tamaño | Cuadrado, ≥1024 px |
| Consistencia | Mismo grosor de contorno y nivel de detalle que los animales ya generados |

Destino: `assets/animales/<slug>.png`.
