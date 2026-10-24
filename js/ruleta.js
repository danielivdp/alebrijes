// Ruleta SVG reutilizable. La flecha está arriba; girarA(i) deja el segmento i bajo la flecha.
const SVG = "http://www.w3.org/2000/svg";

export function crearRuleta(contenedor, segmentos) {
  const n = segmentos.length;
  const paso = 360 / n;
  const svg = document.createElementNS(SVG, "svg");
  svg.setAttribute("viewBox", "-110 -110 220 220");
  svg.setAttribute("aria-hidden", "true");

  segmentos.forEach((seg, i) => {
    const a0 = ((i * paso - 90) * Math.PI) / 180;
    const a1 = (((i + 1) * paso - 90) * Math.PI) / 180;
    const path = document.createElementNS(SVG, "path");
    path.setAttribute(
      "d",
      `M0 0 L${100 * Math.cos(a0)} ${100 * Math.sin(a0)} A100 100 0 ${paso > 180 ? 1 : 0} 1 ${100 * Math.cos(a1)} ${100 * Math.sin(a1)} Z`
    );
    path.setAttribute("fill", seg.color);
    path.setAttribute("stroke", "#1a0033");
    path.setAttribute("stroke-width", "3");
    svg.append(path);

    const medio = i * paso + paso / 2;
    const texto = document.createElementNS(SVG, "text");
    texto.setAttribute("transform", `rotate(${medio}) translate(0 -66) rotate(${seg.emoji ? -medio : 0})`);
    texto.setAttribute("text-anchor", "middle");
    texto.setAttribute("dominant-baseline", "central");
    texto.setAttribute("font-size", seg.emoji ? "30" : "15");
    texto.setAttribute("font-family", "Fredoka, sans-serif");
    texto.setAttribute("font-weight", "700");
    texto.setAttribute("fill", "#1a0033");
    texto.textContent = seg.emoji || seg.etiqueta;
    svg.append(texto);
  });

  const centro = document.createElementNS(SVG, "circle");
  centro.setAttribute("r", "14");
  centro.setAttribute("fill", "#fff");
  centro.setAttribute("stroke", "#1a0033");
  centro.setAttribute("stroke-width", "4");
  svg.append(centro);

  const borde = document.createElementNS(SVG, "circle");
  borde.setAttribute("r", "104");
  borde.setAttribute("fill", "none");
  borde.setAttribute("stroke", "#1a0033");
  borde.setAttribute("stroke-width", "8");
  svg.append(borde);

  contenedor.append(svg);

  let giro = 0;
  return {
    girarA(indice) {
      const destino = 360 - (indice * paso + paso / 2);
      const actual = ((giro % 360) + 360) % 360;
      giro += 360 * 5 + ((destino - actual + 360) % 360);
      svg.style.transform = `rotate(${giro}deg)`;
      return new Promise((resolver) => {
        const fin = () => { svg.removeEventListener("transitionend", fin); resolver(); };
        svg.addEventListener("transitionend", fin);
        // respaldo por si no se dispara transitionend (pestaña oculta, sin animaciones)
        setTimeout(fin, 3500);
      });
    },
  };
}
