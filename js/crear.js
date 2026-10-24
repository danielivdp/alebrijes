import { crearRuleta } from "./ruleta.js";
import { agrupar, aplicarPaleta, rotarTono } from "./recolor.js";

const COLORES_RULETA = ["#ff2e9a", "#ffd000", "#00d98a", "#00c2ff", "#ff7a00", "#b58cff"];

// "Sorpresa" no tiene colores: rota el tono de toda la imagen al azar
const PALETAS = [
  { etiqueta: "Original", colores: null },
  { etiqueta: "Oaxaca", colores: ["#e6332a", "#ffb000", "#00a6a6", "#7b2ff7", "#ff5fa2", "#2bb24c"] },
  { etiqueta: "Noche", colores: ["#3b2cc2", "#ff2e9a", "#ffd000", "#00c2ff", "#8a1cff", "#ff7a00"] },
  { etiqueta: "Selva", colores: ["#1f9e45", "#ffd000", "#ff6a00", "#00b3a4", "#c1e000", "#e6332a"] },
  { etiqueta: "Mar", colores: ["#0077d9", "#00d4c8", "#ffffff", "#7ad3ff", "#ffcf3a", "#ff7aa8"] },
  { etiqueta: "Sorpresa", colores: "tono" },
];

const $ = (id) => document.getElementById(id);
const azar = (n) => Math.floor(Math.random() * n);

const manifiesto = await fetch("assets/manifest.json").then((r) => r.json());
const animales = manifiesto.animales;

const segmentos = animales.map((a, i) => ({ etiqueta: a.nombre, emoji: a.emoji, color: COLORES_RULETA[i % COLORES_RULETA.length] }));
const ruletaA = crearRuleta($("ruleta-a"), segmentos);
const ruletaB = crearRuleta($("ruleta-b"), segmentos);
const ruletaColor = crearRuleta(
  $("ruleta-color"),
  PALETAS.map((p, i) => ({ etiqueta: p.etiqueta, color: Array.isArray(p.colores) ? p.colores[0] : COLORES_RULETA[i] }))
);

const estado = { a: null, b: null, nombre: null, original: null, grupos: null };

$("girar-a").addEventListener("click", async () => {
  bloquear(true);
  const i = azar(animales.length);
  await ruletaA.girarA(i);
  estado.a = animales[i];
  $("elegido-a").textContent = `${estado.a.emoji} ${estado.a.nombre}`;
  olvidarNombre();
  bloquear(false);
  $("girar-b").disabled = false;
  if (estado.b && estado.b.slug === estado.a.slug) reiniciarB();
  actualizarBotones();
});

$("girar-b").addEventListener("click", async () => {
  bloquear(true);
  // nunca el mismo animal que la ruleta A
  const otros = animales.map((_, i) => i).filter((i) => animales[i].slug !== estado.a.slug);
  const i = otros[azar(otros.length)];
  await ruletaB.girarA(i);
  estado.b = animales[i];
  $("elegido-b").textContent = `${estado.b.emoji} ${estado.b.nombre}`;
  olvidarNombre();
  bloquear(false);
  actualizarBotones();
});

$("lanzar").addEventListener("click", async () => {
  bloquear(true);
  const dado = $("dado");
  dado.classList.add("rodando");
  let valor = 1;
  for (let t = 0; t < 12; t++) {
    valor = 1 + azar(6);
    pintarDado(valor);
    await esperar(70 + t * 12);
  }
  dado.classList.remove("rodando");
  // par: empieza el animal A; impar: empieza el B
  const [primero, segundo] = valor % 2 === 0 ? [estado.a, estado.b] : [estado.b, estado.a];
  estado.nombre = primero.inicio + segundo.fin;
  $("nombre").textContent = `${valor} → ¡${estado.nombre}!`;
  bloquear(false);
  actualizarBotones();
});

$("mezclar").addEventListener("click", async () => {
  bloquear(true);
  const { a, b } = estado;
  $("cap-a").textContent = a.nombre;
  $("cap-b").textContent = b.nombre;
  $("cap-mezcla").textContent = estado.nombre;

  dibujar($("lienzo-a"), await cargarImagen(`assets/animales/${a.slug}.png`), () => marcadorAnimal(a));
  dibujar($("lienzo-b"), await cargarImagen(`assets/animales/${b.slug}.png`), () => marcadorAnimal(b));

  const [x, y] = [a.slug, b.slug].sort();
  const lienzo = $("lienzo-mezcla");
  dibujar(lienzo, await cargarImagen(`assets/mezclas/${x}-${y}.png`), () => marcadorMezcla(a, b));
  const ctx = lienzo.getContext("2d", { willReadFrequently: true });
  estado.original = ctx.getImageData(0, 0, lienzo.width, lienzo.height);
  estado.grupos = agrupar(estado.original);

  const fig = $("resultado");
  fig.classList.remove("revelar");
  void fig.offsetWidth;
  fig.classList.add("revelar");

  $("panel-color").classList.remove("oculto");
  $("elegido-color").textContent = "";
  bloquear(false);
  actualizarBotones();
});

$("girar-color").addEventListener("click", async () => {
  bloquear(true);
  const i = azar(PALETAS.length);
  await ruletaColor.girarA(i);
  const paleta = PALETAS[i];
  const lienzo = $("lienzo-mezcla");
  const ctx = lienzo.getContext("2d");
  let datos = estado.original;
  if (paleta.colores === "tono") datos = rotarTono(estado.original, 60 + azar(240));
  else if (paleta.colores) datos = aplicarPaleta(estado.original, estado.grupos, mezclar(paleta.colores));
  ctx.putImageData(datos, 0, 0);
  $("elegido-color").textContent = paleta.etiqueta;
  bloquear(false);
});

$("descargar").addEventListener("click", () => {
  $("lienzo-mezcla").toBlob((blob) => {
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = `${estado.nombre}.png`;
    a.click();
    setTimeout(() => URL.revokeObjectURL(a.href), 1000);
  });
});

$("otra-vez").addEventListener("click", () => {
  Object.assign(estado, { a: null, b: null, nombre: null, original: null, grupos: null });
  for (const id of ["elegido-a", "elegido-b", "nombre", "elegido-color"]) $(id).textContent = "";
  for (const id of ["cap-a", "cap-b", "cap-mezcla"]) $(id).textContent = "?";
  for (const id of ["lienzo-a", "lienzo-b", "lienzo-mezcla"]) {
    const c = $(id);
    c.getContext("2d").clearRect(0, 0, c.width, c.height);
  }
  pintarDado(0);
  $("panel-color").classList.add("oculto");
  $("girar-b").disabled = true;
  actualizarBotones();
  window.scrollTo({ top: 0, behavior: "smooth" });
});

function reiniciarB() {
  estado.b = null;
  $("elegido-b").textContent = "";
}

function actualizarBotones() {
  const ambos = Boolean(estado.a && estado.b);
  $("lanzar").disabled = !ambos;
  $("mezclar").disabled = !(ambos && estado.nombre);
}

// Al cambiar un animal, el nombre anterior ya no aplica
function olvidarNombre() {
  estado.nombre = null;
  $("nombre").textContent = "";
  pintarDado(0);
}

let bloqueado = false;
function bloquear(si) {
  bloqueado = si;
  for (const b of document.querySelectorAll("main button")) {
    if (si) { b.dataset.antes = b.disabled; b.disabled = true; }
    else { b.disabled = b.dataset.antes === "true"; }
  }
}

function pintarDado(valor) {
  const caras = { 0: [], 1: [4], 2: [0, 8], 3: [0, 4, 8], 4: [0, 2, 6, 8], 5: [0, 2, 4, 6, 8], 6: [0, 2, 3, 5, 6, 8] };
  [...$("dado").children].forEach((punto, i) => punto.classList.toggle("on", caras[valor].includes(i)));
}

// Baraja la paleta para que el mismo animal no salga siempre igual con la misma paleta
function mezclar(colores) {
  const c = [...colores];
  for (let i = c.length - 1; i > 0; i--) {
    const j = azar(i + 1);
    [c[i], c[j]] = [c[j], c[i]];
  }
  return c;
}

const esperar = (ms) => new Promise((r) => setTimeout(r, ms));

function cargarImagen(src) {
  return new Promise((resolver) => {
    const img = new Image();
    img.onload = () => resolver(img);
    img.onerror = () => resolver(null);
    img.src = src;
  });
}

function dibujar(lienzo, img, marcador) {
  const ctx = lienzo.getContext("2d", { willReadFrequently: true });
  ctx.clearRect(0, 0, lienzo.width, lienzo.height);
  if (img) ctx.drawImage(img, 0, 0, lienzo.width, lienzo.height);
  else marcador(ctx, lienzo.width);
}

// Marcadores mientras no existan las imágenes generadas: colores planos y contorno negro,
// igual que el estilo pedido, para que la ruleta de colores también se pueda probar.
function marcadorAnimal(animal) {
  return (ctx, t) => {
    ctx.fillStyle = "#ffe9b8";
    ctx.strokeStyle = "#1a0033";
    ctx.lineWidth = t * 0.025;
    ctx.beginPath();
    ctx.arc(t / 2, t / 2, t * 0.4, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();
    emoji(ctx, animal.emoji, t / 2, t / 2, t * 0.42);
  };
}

function marcadorMezcla(a, b) {
  return (ctx, t) => {
    const colores = ["#ff2e9a", "#ffd000", "#00d98a", "#00c2ff", "#ff7a00"];
    ctx.lineWidth = t * 0.02;
    ctx.strokeStyle = "#1a0033";
    // cuerpo
    ctx.fillStyle = colores[0];
    ctx.beginPath();
    ctx.ellipse(t / 2, t * 0.55, t * 0.38, t * 0.3, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();
    // zigzag
    ctx.fillStyle = colores[1];
    ctx.beginPath();
    for (let i = 0; i <= 8; i++) ctx.lineTo(t * (0.16 + i * 0.085), t * (i % 2 ? 0.52 : 0.6));
    ctx.lineTo(t * 0.84, t * 0.66);
    for (let i = 8; i >= 0; i--) ctx.lineTo(t * (0.16 + i * 0.085), t * (i % 2 ? 0.58 : 0.66));
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    // puntos
    for (let i = 0; i < 7; i++) {
      ctx.fillStyle = colores[2 + (i % 3)];
      ctx.beginPath();
      ctx.arc(t * (0.26 + i * 0.08), t * (i % 2 ? 0.4 : 0.76), t * 0.03, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
    }
    emoji(ctx, a.emoji, t * 0.36, t * 0.34, t * 0.26);
    emoji(ctx, b.emoji, t * 0.64, t * 0.34, t * 0.26);
  };
}

function emoji(ctx, texto, x, y, tam) {
  ctx.font = `${tam}px "Apple Color Emoji", "Segoe UI Emoji", "Noto Color Emoji", sans-serif`;
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.fillText(texto, x, y);
}
