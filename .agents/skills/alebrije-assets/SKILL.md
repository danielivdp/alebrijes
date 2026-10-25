---
name: alebrije-assets
description: Genera los assets de imagen del sitio Alebrijes — animales base, alebrijes mezcla (uno por pareja de animales), ilustraciones del cuento e ícono de la app de Apple TV — con un estilo visual común y la nomenclatura que espera la página. Usar cuando se pida crear, regenerar o completar imágenes de animales, mezclas, páginas del cuento o el ícono de la app de este repo. No usar para fotos de Wikipedia (esas se descargan, no se generan) ni para editar HTML/CSS.
---

# Assets del sitio Alebrijes

Este skill produce cuatro tipos de imágenes. La generación se hace con el skill de sistema `$imagegen`
en **modo built-in** (`image_gen`), una llamada por asset. No uses el CLI de fallback salvo que el
usuario lo pida: el CLI con `gpt-image-2` no soporta fondo transparente.

| Tipo | Guía | Destino | Cantidad |
|---|---|---|---|
| Animal base | `references/animales.md` | `assets/animales/<slug>.png` | uno por animal del manifiesto |
| Alebrije mezcla | `references/mezclas.md` | `assets/mezclas/<slugA>-<slugB>.png` | una por pareja (orden alfabético) |
| Ilustración del cuento | `references/cuento.md` | `assets/cuento/pagina-NN.png` | páginas 01–07 y 09 |
| Ícono de la app (tvOS) | `references/icono.md` | `assets/icono/don-pedro.png` | uno |

La lista de animales vive en `assets/manifest.json` (fuente única). No inventes animales fuera de ella;
si el usuario pide uno nuevo, agrégalo primero al manifiesto.

## Flujo

1. Lee `assets/manifest.json` y `references/estilo.md` (bloque de estilo obligatorio para todo).
2. Corre `python3 .agents/skills/alebrije-assets/scripts/check_assets.py` para ver qué falta.
3. Genera **solo lo faltante** o lo que el usuario pidió, siguiendo la guía del tipo.
   Orden obligatorio: animales base antes que mezclas (las mezclas usan los animales como referencia).
4. Revisa cada imagen contra la checklist de su guía. Si falla, itera con un solo cambio.
5. Copia la imagen elegida desde `$CODEX_HOME/generated_images/...` al destino exacto. No sobrescribas
   un asset existente salvo que el usuario lo pida; si no, guarda como `<nombre>-v2.png`.
6. Vuelve a correr `check_assets.py` y reporta: archivos creados, prompt final de cada uno y lo que siga faltando.

## Reglas comunes

- PNG, sin texto, sin firmas, sin marcas de agua, sin marco.
- Nombres de archivo: minúsculas, sin acentos, slugs del manifiesto.
- No hagas commit ni push; el usuario revisa las imágenes primero.
