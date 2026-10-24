import { crearRuleta } from "./ruleta.js";
import { agrupar, aplicarPaleta, rotarTono } from "./recolor.js";
import { lanzarConfeti } from "./confeti.js";

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

const PASOS = [
  { boton: "🎡 Girar animal 1", activa: "ruleta-a" },
  { boton: "🎡 Girar animal 2", activa: "ruleta-b" },
  { boton: "🎨 Girar colores", activa: "ruleta-color" },
  { boton: "✨ ¡Revelar mi alebrije!", activa: null },
];

const $ = (id) => document.getElementById(id);
const azar = (n) => Math.floor(Math.random() * n);

const manifiesto = await fetch("assets/manifest.json").then((r) => r.json());
const animales = manifiesto.animales;

const segmentos = animales.map((a, i) => ({ etiqueta: a.nombre, emoji: a.emoji, color: COLORES_RULETA[i % COLORES_RULETA.length] }));
const ruletas = {
  "ruleta-a": crearRuleta($("ruleta-a"), segmentos),
  "ruleta-b": crearRuleta($("ruleta-b"), segmentos),
  "ruleta-color": crearRuleta(
    $("ruleta-color"),
    PALETAS.map((p, i) => ({ etiqueta: p.etiqueta, color: Array.isArray(p.colores) ? p.colores[0] : COLORES_RULETA[i] }))
  ),
};

let estado;
let ocupado = false;

function reiniciar() {
  estado = { paso: 0, a: null, b: null, paleta: null, nombre: null, mezcla: null };
  for (const id of ["elegido-a", "elegido-b", "elegido-color"]) $(id).textContent = "";
  for (const id of ["medalla-a", "medalla-b"]) $(id).hidden = true;
  mostrarPaso();
}

function mostrarPaso() {
  const paso = PASOS[estado.paso];
  $("accion").textContent = paso.boton;
  $("pista").textContent = `Paso ${estado.paso + 1} de ${PASOS.length}`;
  for (const id of Object.keys(ruletas)) $(id).classList.toggle("activa", id === paso.activa);
}

async function avanzar() {
  if (ocupado) return;
  ocupado = true;
  $("accion").disabled = true;
  try {
    if (estado.paso === 0) await girarAnimal("a", animales);
    else if (estado.paso === 1) await girarAnimal("b", animales.filter((x) => x.slug !== estado.a.slug));
    else if (estado.paso === 2) await girarColores();
    else await revelar();
  } finally {
    ocupado = false;
    $("accion").disabled = false;
  }
}

async function girarAnimal(lado, opciones) {
  // la ruleta B nunca cae en el animal de la A
  const animal = opciones[azar(opciones.length)];
  await ruletas[`ruleta-${lado}`].girarA(animales.indexOf(animal));
  estado[lado] = animal;
  mostrarMedalla($(`medalla-${lado}`), animal);
  $(`elegido-${lado}`).textContent = animal.nombre;

  if (lado === "a") {
    estado.paso = 1;
    mostrarPaso();
    return;
  }
  estado.nombre = estado.a.inicio + estado.b.fin;
  estado.mezcla = prepararMezcla(estado.a, estado.b);
  await esperar(500);
  $("nombre-titulo").textContent = `¡${estado.nombre}!`;
  $("nombre-mezcla").textContent = `${estado.a.nombre} + ${estado.b.nombre}`;
  abrir($("pop-nombre"));
}

$("a-colores").addEventListener("click", () => {
  $("pop-nombre").close();
  estado.paso = 2;
  mostrarPaso();
});

async function girarColores() {
  const i = azar(PALETAS.length);
  await ruletas["ruleta-color"].girarA(i);
  estado.paleta = PALETAS[i];
  $("elegido-color").textContent = estado.paleta.etiqueta;
  estado.paso = 3;
  mostrarPaso();
}

async function revelar() {
  const { original, grupos } = await estado.mezcla;
  const paleta = estado.paleta;
  let datos = original;
  if (paleta.colores === "tono") datos = rotarTono(original, 60 + azar(240));
  else if (paleta.colores) datos = aplicarPaleta(original, grupos, barajar(paleta.colores));
  const lienzo = $("lienzo-mezcla");
  lienzo.getContext("2d").putImageData(datos, 0, 0);
  lienzo.setAttribute("aria-label", `Tu alebrije ${estado.nombre}, mezcla de ${estado.a.nombre} y ${estado.b.nombre}`);
  $("alebrije-titulo").textContent = estado.nombre;
  abrir($("pop-alebrije"));
}

// Se carga y analiza mientras el niño ve el nombre, para que revelar sea instantáneo
async function prepararMezcla(a, b) {
  const lienzo = document.createElement("canvas");
  lienzo.width = lienzo.height = 1024;
  const ctx = lienzo.getContext("2d", { willReadFrequently: true });
  const [x, y] = [a.slug, b.slug].sort();
  const img = await cargarImagen(`assets/mezclas/${x}-${y}.png`);
  if (img) ctx.drawImage(img, 0, 0, 1024, 1024);
  else marcadorMezcla(ctx, a, b);
  const original = ctx.getImageData(0, 0, 1024, 1024);
  return { original, grupos: agrupar(original) };
}

function abrir(dialogo) {
  dialogo.showModal();
  // dentro del diálogo para quedar sobre el fondo oscurecido, pero detrás de la tarjeta
  dialogo.prepend($("confeti"));
  lanzarConfeti($("confeti"));
}

function mostrarMedalla(img, animal) {
  img.hidden = false;
  img.alt = animal.nombre;
  img.onerror = () => { img.hidden = true; };
  img.src = `assets/animales/${animal.slug}.png`;
  img.classList.remove("aparece");
  void img.offsetWidth; // reinicia la animación
  img.classList.add("aparece");
}

$("accion").addEventListener("click", avanzar);
for (const id of Object.keys(ruletas)) {
  $(id).addEventListener("click", () => {
    if ($(id).classList.contains("activa")) avanzar();
  });
}

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
  $("pop-alebrije").close();
  reiniciar();
});

// Esc cierra el diálogo; el juego sigue en el paso que corresponde
$("pop-nombre").addEventListener("cancel", () => {
  estado.paso = 2;
  mostrarPaso();
});

function barajar(colores) {
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

// Por si se agrega un animal al manifiesto antes de generar sus mezclas
function marcadorMezcla(ctx, a, b) {
  ctx.fillStyle = "#ff2e9a";
  ctx.strokeStyle = "#1a0033";
  ctx.lineWidth = 20;
  ctx.beginPath();
  ctx.arc(512, 512, 400, 0, Math.PI * 2);
  ctx.fill();
  ctx.stroke();
  ctx.font = '300px "Apple Color Emoji", "Segoe UI Emoji", "Noto Color Emoji", sans-serif';
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  ctx.fillText(a.emoji, 370, 512);
  ctx.fillText(b.emoji, 654, 512);
}

reiniciar();
