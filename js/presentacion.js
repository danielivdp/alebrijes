// Modo presentación: todo el sitio avanza con la barra espaciadora (o un clicker de presentaciones).
// Un solo detector global; los botones nunca reciben el espacio, así no hay doble avance.
const SIGUIENTE = new Set([" ", "PageDown", "ArrowRight"]);
const ANTERIOR = new Set(["PageUp", "ArrowLeft"]);

export function alAvanzar(siguiente, anterior = () => {}) {
  addEventListener("keydown", (e) => {
    if (e.metaKey || e.ctrlKey || e.altKey) return;
    if (e.key === "Home") {
      location.href = "index.html";
      return;
    }
    const atras = ANTERIOR.has(e.key) || (e.key === " " && e.shiftKey);
    if (!atras && !SIGUIENTE.has(e.key)) return;
    e.preventDefault();
    e.stopPropagation();
    // mantener la tecla apretada no salta varias pantallas
    if (e.repeat) return;
    if (atras) anterior();
    else siguiente();
  }, true);
  // el botón con foco se activa al soltar el espacio: lo bloqueamos también
  addEventListener("keyup", (e) => {
    if (e.key === " ") {
      e.preventDefault();
      e.stopPropagation();
    }
  }, true);
}

export function precargar(rutas) {
  for (const src of rutas) new Image().src = src;
}
