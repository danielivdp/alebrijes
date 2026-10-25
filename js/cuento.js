import { alAvanzar, precargar } from "./presentacion.js?v=12";

// El texto vive en assets/cuento.json, compartido con la app de Apple TV (tvos/).
const { paginas } = await fetch("assets/cuento.json", { cache: "no-cache" }).then((r) => r.json());
const PAGINAS = paginas.map((p) => ({ ...p, imagen: `assets/${p.imagen}` }));

const libro = document.getElementById("libro");
const avance = document.getElementById("avance");

let actual = 0;

function lamina(pagina, numero) {
  const cont = document.createElement("div");
  cont.className = "lamina" + (pagina.foto ? " foto" : "");

  const img = document.createElement("img");
  img.src = pagina.imagen;
  img.alt = pagina.foto ? pagina.foto.alt : `Ilustración: ${pagina.titulo}`;
  img.addEventListener("error", () => {
    const marcador = document.createElement("div");
    marcador.className = "pendiente";
    marcador.innerHTML = `<span>Ilustración ${numero} en camino ✏️</span>`;
    img.replaceWith(marcador);
  });
  cont.append(img);

  if (pagina.foto) {
    const credito = document.createElement("a");
    credito.className = "credito";
    credito.href = pagina.foto.url;
    credito.target = "_blank";
    credito.rel = "noopener";
    credito.textContent = pagina.foto.texto;
    cont.append(credito);
  }
  return cont;
}

function mostrar(indice) {
  actual = Math.max(0, Math.min(PAGINAS.length - 1, indice));
  const pagina = PAGINAS[actual];

  const texto = document.createElement("div");
  texto.className = "texto";
  texto.innerHTML = `<p class="num">Página ${actual + 1} de ${PAGINAS.length}</p>`;
  const h2 = document.createElement("h2");
  h2.textContent = pagina.titulo;
  texto.append(h2);
  for (const parrafo of pagina.texto) {
    const p = document.createElement("p");
    p.textContent = parrafo;
    texto.append(p);
  }

  const hoja = document.createElement("div");
  hoja.className = "pagina";
  hoja.append(lamina(pagina, actual + 1), texto);
  libro.replaceChildren(hoja);
  libro.classList.remove("entrar");
  void libro.offsetWidth; // reinicia la animación
  libro.classList.add("entrar");

  avance.style.width = `${((actual + 1) / PAGINAS.length) * 100}%`;
  avance.parentElement.setAttribute("aria-valuenow", actual + 1);
  history.replaceState(null, "", `#${actual + 1}`);
}

// Espacio avanza; desde la última página se pasa al juego
alAvanzar(
  () => (actual === PAGINAS.length - 1 ? (location.href = "crear.html") : mostrar(actual + 1)),
  () => mostrar(actual - 1)
);
precargar(PAGINAS.map((p) => p.imagen));

// Deslizar con el dedo
let inicioX = null;
libro.addEventListener("touchstart", (e) => { inicioX = e.touches[0].clientX; }, { passive: true });
libro.addEventListener("touchend", (e) => {
  if (inicioX === null) return;
  const dx = e.changedTouches[0].clientX - inicioX;
  if (Math.abs(dx) > 50) mostrar(actual + (dx < 0 ? 1 : -1));
  inicioX = null;
});

const inicial = parseInt(location.hash.slice(1), 10);
mostrar(Number.isFinite(inicial) ? inicial - 1 : 0);
