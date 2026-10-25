import { crearRuleta } from "./ruleta.js?v=10";
import { agrupar, aplicarPaleta, rotarTono } from "./recolor.js?v=10";
import { lanzarConfeti } from "./confeti.js?v=10";
import { alAvanzar, precargar } from "./presentacion.js?v=10";

const COLORES_RULETA = ["#ff2e9a", "#ffd000", "#00d98a", "#00c2ff", "#ff7a00", "#b58cff"];

// "Sorpresa" no tiene colores: rota el tono de toda la imagen al azar
const PALETAS = [
  { etiqueta: "Original", colores: null },
  { etiqueta: "Oaxaca", colores: ["#e6332a", "#ffb000", "#00a6a6", "#7b2ff7", "#ff5fa2", "#2bb24c"] },
  { etiqueta: "Noche", colores: ["#3b2cc2", "#ff2e9a", "#ffd000", "#00c2ff", "#8a1cff", "#ff7a00"] },
  { etiqueta: "Selva", colores: ["#1f9e45", "#ffd000", "#ff6a00", "#00b3a4", "#c1e000", "#e6332a"] },
  // sin blanco: sobre el fondo crema parece un hueco
  { etiqueta: "Mar", colores: ["#0077d9", "#00d4c8", "#ff8f5c", "#7ad3ff", "#ffcf3a", "#ff7aa8"] },
  { etiqueta: "Sorpresa", colores: "tono" },
];

// Un paso a la vez: solo se ve la ruleta del paso actual
const PASOS = [
  { titulo: "Paso 1 de 3 · Elige el primer animal", boton: "🎡 Girar", ruleta: "ruleta-a" },
  { titulo: "Paso 2 de 3 · Elige el segundo animal", boton: "🎡 Girar", ruleta: "ruleta-b" },
  { titulo: "Paso 3 de 3 · Elige los colores", boton: "🎨 Girar", ruleta: "ruleta-color" },
];

const $ = (id) => document.getElementById(id);
const azar = (n) => Math.floor(Math.random() * n);
const esperar = (ms) => new Promise((r) => setTimeout(r, ms));

const manifiesto = await fetch("assets/manifest.json", { cache: "no-cache" }).then((r) => r.json());
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
// cada niño crea uno: no se repite una pareja hasta agotar las 15
const usadas = new Set();
const pareja = (a, b) => [a.slug, b.slug].sort().join("-");
const libres = (a) => animales.filter((b) => b !== a && !usadas.has(pareja(a, b)));

function reiniciar() {
  estado = { paso: 0, a: null, b: null, paleta: null, nombre: null, mezcla: null, nombreListo: false };
  for (const id of ["medalla-a", "medalla-b"]) $(id).hidden = true;
  ficha("ficha-a", "?", "Animal 1");
  ficha("ficha-b", "?", "Animal 2");
  ficha("ficha-nombre", "✨", "¿?");
  mostrarPaso();
}

function mostrarPaso() {
  const paso = PASOS[estado.paso];
  $("titulo-paso").textContent = paso.titulo;
  $("accion").textContent = paso.boton;
  $("elegido").textContent = "";
  $("escenario").classList.remove("duo");
  $("nombre-revelado").hidden = true;
  for (const id of Object.keys(ruletas)) $(id).hidden = id !== paso.ruleta;
  for (const [i, id] of ["ficha-a", "ficha-b", "ficha-nombre"].entries()) {
    $(id).classList.toggle("actual", i === estado.paso);
  }
}

async function avanzar() {
  if (ocupado) return;
  ocupado = true;
  $("accion").disabled = true;
  try {
    if (estado.paso === 0) {
      if (!animales.some((a) => libres(a).length)) usadas.clear();
      await girarAnimal("a", animales.filter((a) => libres(a).length));
    }
    else if (estado.paso === 1 && estado.nombreListo) aColores();
    else if (estado.paso === 1) await girarAnimal("b", libres(estado.a));
    else await girarColores();
  } finally {
    ocupado = false;
    $("accion").disabled = false;
  }
}

async function girarAnimal(lado, opciones) {
  // la ruleta B nunca cae en el animal de la A ni en una pareja ya usada
  const animal = opciones[azar(opciones.length)];
  await ruletas[`ruleta-${lado}`].girarA(animales.indexOf(animal));
  estado[lado] = animal;
  mostrarMedalla($(`medalla-${lado}`), animal);
  $("elegido").textContent = `¡${animal.nombre}!`;
  ficha(`ficha-${lado}`, imagenAnimal(animal), animal.nombre);
  await esperar(1400);

  if (lado === "a") {
    estado.paso = 1;
    mostrarPaso();
    return;
  }
  usadas.add(pareja(estado.a, estado.b));
  estado.nombre = estado.a.inicio + estado.b.fin;
  estado.mezcla = prepararMezcla(estado.a, estado.b);
  estado.nombreListo = true;
  revelarNombre();
}

// El nombre se revela en la misma pantalla, junto a las dos ruedas con sus animales
function revelarNombre() {
  $("titulo-paso").textContent = "Tu alebrije se llama…";
  $("ruleta-a").hidden = false;
  $("escenario").classList.add("duo");
  const nombre = $("nombre-revelado");
  nombre.textContent = `¡${estado.nombre}!`;
  nombre.style.setProperty("--letras", estado.nombre.length + 2);
  nombre.hidden = false;
  $("accion").textContent = "🎨 ¡Ahora los colores!";
  ficha("ficha-nombre", "✨", estado.nombre);
  $("ficha-b").classList.remove("actual");
  $("ficha-nombre").classList.add("actual");
  document.body.append($("confeti"));
  lanzarConfeti($("confeti"));
}

function aColores() {
  estado.paso = 2;
  mostrarPaso();
}

async function girarColores() {
  const i = azar(PALETAS.length);
  await ruletas["ruleta-color"].girarA(i);
  estado.paleta = PALETAS[i];
  $("elegido").textContent = `¡${estado.paleta.etiqueta}!`;
  await esperar(900);
  await revelar();
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
  $("alebrije-titulo").textContent = `¡${estado.nombre}!`;
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

function mostrarMedalla(medalla, animal) {
  const img = medalla.querySelector("img");
  medalla.hidden = false;
  img.alt = animal.nombre;
  img.onerror = () => { medalla.hidden = true; };
  img.src = `assets/animales/${animal.slug}.png`;
  medalla.classList.remove("aparece");
  void medalla.offsetWidth; // reinicia la animación
  medalla.classList.add("aparece");
}

function imagenAnimal(animal) {
  const img = new Image();
  img.src = `assets/animales/${animal.slug}.png`;
  img.alt = "";
  return img;
}

function ficha(id, contenido, texto) {
  const caja = $(id).querySelector(".ficha-img");
  caja.replaceChildren(contenido);
  $(id).querySelector(".ficha-txt").textContent = texto;
}

$("accion").addEventListener("click", avanzar);
for (const id of Object.keys(ruletas)) $(id).addEventListener("click", avanzar);

$("descargar").addEventListener("click", () => {
  $("lienzo-mezcla").toBlob((blob) => {
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = `${estado.nombre}.png`;
    a.click();
    setTimeout(() => URL.revokeObjectURL(a.href), 1000);
  });
});

$("otra-vez").addEventListener("click", () => $("pop-alebrije").close());
$("pop-alebrije").addEventListener("close", reiniciar);

// Espacio = siguiente paso; después del alebrije final, empieza otro
alAvanzar(() => {
  if ($("pop-alebrije").open) $("pop-alebrije").close();
  else avanzar();
});
precargar(animales.map((a) => `assets/animales/${a.slug}.png`));

function barajar(colores) {
  const c = [...colores];
  for (let i = c.length - 1; i > 0; i--) {
    const j = azar(i + 1);
    [c[i], c[j]] = [c[j], c[i]];
  }
  return c;
}

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
