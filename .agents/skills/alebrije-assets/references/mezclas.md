# Alebrijes mezcla

Una imagen por pareja **no ordenada** de animales del manifiesto (perro+tucán = tucán+perro).
Nombre: slugs en orden alfabético unidos por guion, p. ej. `perro-tucan.png`.

## Requisito previo

Los dos animales base deben existir en `assets/animales/`. Cárgalos con `view_image` y pásalos como
**imágenes de referencia** (no como objetivo de edición) para que la mezcla sea reconocible y conserve el estilo.

## Prompt

```text
Use case: illustration-story
Asset type: game result card, a Mexican alebrije creature that fuses two animals
Input images: Image 1: reference for <animal A>; Image 2: reference for <animal B>
Primary request: one fantastical alebrije creature that clearly combines a <animal A> and a <animal B>
Subject: a single creature with recognizable features of both animals (for example the head of one and
wings, tail, legs or shell of the other), decorated in Mexican alebrije folk-art style: dots, zigzags,
spirals and stripes in bright saturated colors
Composition/framing: centered, entire body visible with margin on all sides, square canvas
Background: transparent
<bloque de estilo de estilo.md>
Avoid: more than one creature, a third animal, scary or aggressive look, gore, props, ground
```

Decide tú qué rasgos aporta cada animal para que **ambos** se reconozcan a primera vista; prioriza los
rasgos más icónicos (pico del tucán, caparazón de la tortuga, branquias del ajolote, alas de la mariposa…).

## Checklist

| Revisar | Aceptable |
|---|---|
| Se reconocen los dos animales | Un niño de 6 años podría nombrar ambos |
| Patrones de alebrije | Presentes, en regiones de color sólido |
| Paleta | ≈5–8 colores distintos más el negro del contorno |
| Fondo | Transparente de verdad |
| Tono | Amigable, apto para niños |
| Consistencia | Mismo estilo que las mezclas ya generadas |

Destino: `assets/mezclas/<slugA>-<slugB>.png`.
