# Ícono de la app (Don Pedro)

Ícono de la app de Apple TV (`tvos/`). En tvOS el ícono es una pila de capas con efecto parallax:
`tvos/scripts/iconos.swift` dibuja la capa de fondo (tinta, manchas de color y cenefa) y pone **esta imagen
como capa de enfrente**. Por eso aquí solo se genera la figura, con fondo transparente.

| Archivo | Qué es |
|---|---|
| `assets/icono/don-pedro.png` | Cabeza y hombros de Don Pedro Linares, el mismo personaje del cuento, fondo transparente |

## Referencia de personaje

Antes de generar, carga `assets/cuento/pagina-01.png` con `view_image` y úsala como referencia: tiene que ser
**el mismo Pedro** (cara, bigote, pelo, ropa de cartonero). Es una persona real: personaje de libro infantil
estilizado, no retrato realista (ver `cuento.md`).

## Prompt

```text
Use case: app-icon-foreground
Asset type: foreground layer of a layered Apple TV app icon, transparent background
Primary request: close-up head-and-shoulders portrait of Don Pedro Linares, the cardboard artisan from the
  reference image (same face, mustache, hair and clothes), smiling warmly at the viewer, holding up a small
  colorful paper-mache alebrije creature next to his face
Composition/framing: square 1:1, subject centered and filling ~85% of the height, face large and readable
  at very small sizes, simple silhouette, nothing touching the edges
Background: fully transparent (real alpha), no floor, no shadow, no backdrop
<bloque de estilo de estilo.md>
Avoid: photorealism, likeness claims of a real person, text in the image, thin details that vanish when small
```

## Checklist

| Revisar | Aceptable |
|---|---|
| Mismo Pedro que el cuento | Se reconoce al de `pagina-01.png`: cara, bigote, ropa |
| Legible en chico | Reducida a 240 px de alto, la cara y la sonrisa se distinguen |
| Fondo | Transparente de verdad (canal alpha), sin piso ni sombra |
| Formato | PNG cuadrado, mínimo 1024×1024 |
| Bordes | Nada toca el borde del lienzo (el parallax mueve la capa) |

Destino: `assets/icono/don-pedro.png`. Después, desde `tvos/`: `swift scripts/iconos.swift` regenera el ícono.
