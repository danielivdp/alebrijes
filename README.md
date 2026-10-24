# Alebrijes

Sitio para niños sobre los alebrijes, publicado con GitHub Pages: https://danielivdp.github.io/alebrijes/

| Página | Qué es |
|---|---|
| `index.html` | Portada |
| `cuento.html` + `js/cuento.js` | Cuento de 10 páginas sobre el origen de los alebrijes (texto adaptado de Wikipedia) |
| `crear.html` + `js/crear.js` | Juego de una pantalla: dos ruletas eligen animales (con revelación del nombre y confeti), una ruleta de colores y la revelación del alebrije |
| `creditos.html` | Fuentes y licencias |

Las imágenes viven en `assets/` y las genera Codex con el skill `.agents/skills/alebrije-assets`
(`$alebrije-assets`). Para ver qué falta: `python3 .agents/skills/alebrije-assets/scripts/check_assets.py`.
Mientras falte una imagen, el sitio muestra un marcador.

Para probar localmente (el juego necesita servidor por `fetch`): `python3 -m http.server 8000`.
