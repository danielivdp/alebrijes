// Confeti mexicano: banderitas de papel picado y flores de cempasúchil.
const COLORES = ["#ff2e9a", "#ffd000", "#00d98a", "#00c2ff", "#ff7a00", "#7b2ff7"];

export function lanzarConfeti(lienzo, duracion = 4500) {
  if (matchMedia("(prefers-reduced-motion: reduce)").matches) return;
  const ctx = lienzo.getContext("2d");
  const dpr = Math.min(2, devicePixelRatio || 1);
  const ancho = innerWidth;
  const alto = innerHeight;
  lienzo.width = ancho * dpr;
  lienzo.height = alto * dpr;
  ctx.scale(dpr, dpr);

  const escala = Math.max(0.7, Math.min(1.3, ancho / 900));
  const piezas = Array.from({ length: 150 }, () => ({
    x: Math.random() * ancho,
    y: -20 - Math.random() * alto * 0.6,
    vy: 2 + Math.random() * 3,
    fase: Math.random() * Math.PI * 2,
    giro: (Math.random() - 0.5) * 0.12,
    rot: Math.random() * Math.PI * 2,
    tam: (10 + Math.random() * 12) * escala,
    color: COLORES[Math.floor(Math.random() * COLORES.length)],
    flor: Math.random() < 0.22,
  }));

  const inicio = performance.now();
  function cuadro(t) {
    const pasado = t - inicio;
    ctx.clearRect(0, 0, ancho, alto);
    ctx.globalAlpha = Math.min(1, Math.max(0, (duracion - pasado) / 800));
    for (const p of piezas) {
      p.y += p.vy;
      p.x += Math.sin(p.fase + pasado / 400) * 1.2;
      p.rot += p.giro;
      ctx.save();
      ctx.translate(p.x, p.y);
      ctx.rotate(p.rot);
      if (p.flor) flor(ctx, p.tam * 0.6);
      else banderita(ctx, p.tam, p.color);
      ctx.restore();
    }
    if (pasado < duracion) requestAnimationFrame(cuadro);
    else ctx.clearRect(0, 0, ancho, alto);
  }
  requestAnimationFrame(cuadro);
}

function banderita(ctx, t, color) {
  const w = t;
  const h = t * 1.2;
  ctx.fillStyle = color;
  ctx.beginPath();
  ctx.moveTo(-w / 2, -h / 2);
  ctx.lineTo(w / 2, -h / 2);
  ctx.lineTo(w / 2, h / 2);
  // borde inferior en picos, como el papel picado
  const picos = 4;
  for (let i = picos; i >= 0; i--) {
    ctx.lineTo(-w / 2 + (w * i) / picos, i % 2 ? h / 2 - t * 0.22 : h / 2);
  }
  ctx.closePath();
  ctx.fill();
  // calado al centro
  ctx.fillStyle = "rgba(255,255,255,0.75)";
  ctx.beginPath();
  ctx.moveTo(0, -h * 0.22);
  ctx.lineTo(w * 0.18, 0);
  ctx.lineTo(0, h * 0.22);
  ctx.lineTo(-w * 0.18, 0);
  ctx.closePath();
  ctx.fill();
}

function flor(ctx, r) {
  ctx.fillStyle = "#ff8c00";
  for (let i = 0; i < 8; i++) {
    ctx.beginPath();
    ctx.ellipse(Math.cos((i * Math.PI) / 4) * r * 0.55, Math.sin((i * Math.PI) / 4) * r * 0.55, r * 0.45, r * 0.3, (i * Math.PI) / 4, 0, Math.PI * 2);
    ctx.fill();
  }
  ctx.fillStyle = "#ffc400";
  ctx.beginPath();
  ctx.arc(0, 0, r * 0.4, 0, Math.PI * 2);
  ctx.fill();
}
