# Estilo común

Todas las imágenes deben verse de la misma serie. Incluye este bloque, sin cambios, en cada prompt:

```text
Style/medium: children's picture-book illustration, flat vector-like colors, bold uniform black outlines,
no gradients, no realistic shading, no texture noise, clean solid color regions
Constraints: no text, no letters, no watermark, no signature, no frame
```

## Por qué colores planos y contorno negro

La página tiene una **ruleta de colores** que recolorea las mezclas en el navegador: agrupa los colores
de la imagen en ~6 grupos y los reemplaza por una paleta. Eso solo funciona si:

| Requisito | Si no se cumple |
|---|---|
| Regiones de color sólido | Degradados y sombras se recolorean como manchas |
| Contorno negro grueso y uniforme | El negro no se remapea; sin él la figura se deshace al cambiar la paleta |
| Fondo transparente real (alpha) en animales y mezclas | El fondo se recolorea junto con la criatura |
| Pocos colores distintos (≈5–8) | Grupos demasiado parecidos producen resultados confusos |

Las ilustraciones del cuento no se recolorean, pero mantienen el mismo estilo para que el sitio sea coherente.
