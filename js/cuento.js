import { alAvanzar, precargar } from "./presentacion.js?v=7";

// Texto adaptado de los artículos "Alebrije" de es.wikipedia.org y en.wikipedia.org (CC BY-SA 4.0).
const PAGINAS = [
  {
    titulo: "Don Pedro, el cartonero",
    texto: "Hace mucho tiempo, en la Ciudad de México, vivía Don Pedro Linares. Era cartonero: con papel y engrudo hacía piñatas y máscaras que vendía en el mercado de La Merced.",
    imagen: "assets/cuento/pagina-01.png",
  },
  {
    titulo: "Una fiebre muy fuerte",
    texto: "En 1936, cuando tenía 30 años, Pedro se enfermó con una fiebre muy alta. Se quedó profundamente dormido y sus hermanas lo cuidaban con remedios caseros.",
    imagen: "assets/cuento/pagina-02.png",
  },
  {
    titulo: "El bosque del sueño",
    texto: "Mientras dormía, Pedro soñó con un bosque muy tranquilo, con árboles, rocas, nubes y cielo. Ahí no le dolía nada y se sentía feliz.",
    imagen: "assets/cuento/pagina-03.png",
  },
  {
    titulo: "¡Los animales cambian!",
    texto: "De pronto, los animales del bosque se transformaron en criaturas rarísimas: un burro con alas, un gallo con cuernos de toro y un león con cabeza de perro.",
    imagen: "assets/cuento/pagina-04.png",
  },
  {
    titulo: "«¡Alebrijes! ¡Alebrijes!»",
    texto: "Todas las criaturas gritaban la misma palabra: «¡Alebrijes!». Un señor que caminaba por un sendero de piedras le dijo que todavía no debía estar ahí y le mostró una ventanita para salir.",
    imagen: "assets/cuento/pagina-05.png",
  },
  {
    titulo: "De papel y colores",
    texto: "Pedro despertó sano. Para que todos conocieran a las criaturas de su sueño, las hizo de papel y cartón, y las pintó de colores brillantes, tal como las había visto.",
    imagen: "assets/cuento/pagina-06.png",
  },
  {
    titulo: "Diego y Frida",
    texto: "Los pintores Diego Rivera y Frida Kahlo conocieron su trabajo y le encargaron más alebrijes. Algunos de los que hizo para Diego Rivera hoy están en el Museo Anahuacalli.",
    imagen: "assets/cuento/pagina-07.png",
  },
  {
    titulo: "Alebrijes de madera",
    texto: "Los alebrijes llegaron a Oaxaca. Ahí, Manuel Jiménez y otros artesanos de Arrazola y San Martín Tilcajete empezaron a tallarlos en madera de copal.",
    imagen: "assets/fotos/tallado-arrazola.jpg",
    foto: {
      texto: "Foto: Nsaum75, CC BY-SA 4.0",
      url: "https://commons.wikimedia.org/wiki/File:Alebrije_Carving_in_Arrazola.jpg",
      alt: "Un alebrije tallándose en madera de copal en Arrazola, Oaxaca",
    },
  },
  {
    titulo: "Un premio y una familia",
    texto: "En 1990, Pedro recibió el Premio Nacional de Ciencias y Artes por su creación. Murió en 1992, pero su hijo y sus nietos siguen haciendo alebrijes hasta hoy.",
    imagen: "assets/cuento/pagina-09.png",
  },
  {
    titulo: "La Noche de los Alebrijes",
    texto: "Desde 2007, en la Ciudad de México se hace un desfile de alebrijes gigantes. No hay dos alebrijes iguales… ¿y si inventas el tuyo?",
    imagen: "assets/fotos/alebrijes-monumentales.jpg",
    foto: {
      texto: "Foto: Secretaría de Cultura de la Ciudad de México, CC BY 2.0",
      url: "https://commons.wikimedia.org/wiki/File:Alebrijes_monumentales_en_la_CDMX.jpg",
      alt: "Alebrijes monumentales en Paseo de la Reforma, Ciudad de México",
    },
  },
];

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
  const p = document.createElement("p");
  p.textContent = pagina.texto;
  texto.append(h2, p);

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
