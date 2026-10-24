# Ilustraciones del cuento (páginas 1–7 y 9)

El cuento tiene 10 páginas. Las páginas 8 y 10 usan fotos reales de Wikimedia Commons (se descargan con su
licencia, no se generan). Este skill solo genera las páginas 1–7 y 9; el número del archivo es el número de
página del cuento.

Fuente de los hechos: artículos "Alebrije" de es.wikipedia.org y en.wikipedia.org. No agregues detalles
que no estén en esta tabla (por ejemplo, alebrijes como guías espirituales: eso no viene de la fuente).

| Archivo | Escena |
|---|---|
| `pagina-01.png` | Ciudad de México, años 30. Don Pedro Linares, cartonero, en su taller del barrio de La Merced, rodeado de piñatas, máscaras y figuras de Judas de papel |
| `pagina-02.png` | Pedro enfermo en cama con fiebre, sus hermanas lo cuidan con remedios caseros |
| `pagina-03.png` | El sueño: un bosque tranquilo con árboles, rocas, nubes y cielo; Pedro camina en calma |
| `pagina-04.png` | En el sueño los animales se transforman: un burro con alas, un gallo con cuernos de toro, un león con cabeza de perro |
| `pagina-05.png` | Las criaturas gritan juntas (alegres, no aterradoras); un hombre común de los años 30 (no santo ni túnica) en un sendero de piedras le señala a Pedro una ventana estrecha, con marco visible, como salida |
| `pagina-06.png` | Pedro, ya sano, modela criaturas con papel, engrudo y carrizo y las pinta de colores brillantes |
| `pagina-07.png` | Diego Rivera y Frida Kahlo admiran los alebrijes de Pedro en su taller |
| `pagina-09.png` | Pedro, ya anciano, recibe el Premio Nacional de Ciencias y Artes (1990); detrás, su hijo y sus nietos siguen haciendo alebrijes de cartón en el taller familiar |

## Prompt

```text
Use case: illustration-story
Asset type: full-page illustration for a children's picture book about the origin of alebrijes
Primary request: <escena de la tabla>
Scene/backdrop: <lugar de la escena>, Mexico City 1930s where relevant
Composition/framing: landscape 3:2, the scene fills the whole frame edge to edge; characters shown full body
  with feet and furniture legs visible, nothing cut by a horizontal line or band; no empty floor strip
Lighting/mood: warm, gentle, wonder; never frightening (page 02 must feel caring, not sad)
<bloque de estilo de estilo.md>
Avoid: photorealism, likeness claims of real people, anachronistic objects, text in the image
```

Personas reales (Pedro Linares, Diego Rivera, Frida Kahlo): estilizadas como personajes de libro infantil,
no retratos realistas. Pedro debe verse igual en todas las páginas: después de generar `pagina-01.png`,
cárgala con `view_image` y úsala como referencia de personaje en las siguientes (en `pagina-09.png`,
el mismo Pedro pero mayor: pelo canoso, más arrugas).

## Checklist

| Revisar | Aceptable |
|---|---|
| Fiel a la escena de la tabla | Sin elementos inventados |
| Pedro consistente entre páginas | Misma ropa, cara y proporciones |
| Formato | Horizontal 3:2 (p. ej. 1536×1024), fondo opaco |
| Encuadre completo | La escena llena todo el lienzo; sin franja vacía abajo; pies, camas y muebles completos, nada cortado por una línea horizontal |
| Tono | Apto para niños |

Destino: `assets/cuento/pagina-NN.png`.
