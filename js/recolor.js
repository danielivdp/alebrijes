// Recoloreo de imágenes con colores planos y contorno negro.
// Agrupa los colores de la imagen (k-means) y cambia cada grupo por un color de la paleta.

const OSCURO = 60; // luminancia por debajo de la cual un píxel es contorno y no se toca

const lum = (r, g, b) => 0.299 * r + 0.587 * g + 0.114 * b;

function hexARgb(hex) {
  const v = parseInt(hex.slice(1), 16);
  return [(v >> 16) & 255, (v >> 8) & 255, v & 255];
}

export function agrupar(imageData, k = 6) {
  const d = imageData.data;
  const muestras = [];
  const salto = Math.max(1, Math.floor(d.length / 4 / 20000));
  for (let i = 0; i < d.length; i += 4 * salto) {
    if (d[i + 3] < 128 || lum(d[i], d[i + 1], d[i + 2]) < OSCURO) continue;
    muestras.push([d[i], d[i + 1], d[i + 2]]);
  }
  if (muestras.length === 0) return [];

  // Inicialización por punto más lejano: centros bien separados
  const centros = [muestras[0]];
  while (centros.length < k) {
    let mejor = null;
    let mejorDist = -1;
    for (const m of muestras) {
      const dist = Math.min(...centros.map((c) => dist2(c, m)));
      if (dist > mejorDist) { mejorDist = dist; mejor = m; }
    }
    if (mejorDist === 0) break;
    centros.push(mejor);
  }

  let conteos = [];
  for (let it = 0; it < 10; it++) {
    const sumas = centros.map(() => [0, 0, 0]);
    conteos = centros.map(() => 0);
    for (const m of muestras) {
      const c = cercano(centros, m);
      sumas[c][0] += m[0]; sumas[c][1] += m[1]; sumas[c][2] += m[2];
      conteos[c]++;
    }
    centros.forEach((c, i) => {
      if (conteos[i]) centros[i] = sumas[i].map((s) => s / conteos[i]);
    });
  }
  // Grupos más grandes primero: reciben los primeros colores de la paleta
  return centros
    .map((c, i) => ({ c, n: conteos[i] }))
    .sort((a, b) => b.n - a.n)
    .map((g) => g.c);
}

function dist2(a, b) {
  return (a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2;
}

function cercano(centros, p) {
  let mejor = 0;
  let mejorDist = Infinity;
  for (let i = 0; i < centros.length; i++) {
    const dd = dist2(centros[i], p);
    if (dd < mejorDist) { mejorDist = dd; mejor = i; }
  }
  return mejor;
}

export function aplicarPaleta(original, grupos, colores) {
  const salida = new ImageData(new Uint8ClampedArray(original.data), original.width, original.height);
  const d = salida.data;
  const { width: W, height: H } = original;
  const destino = colores.map(hexARgb);
  const lumGrupo = grupos.map((g) => lum(...g));

  // grupo de cada píxel (-1 = transparente o contorno, no se toca)
  const etiquetas = new Int8Array(W * H).fill(-1);
  for (let p = 0; p < W * H; p++) {
    const i = p * 4;
    if (d[i + 3] === 0 || lum(d[i], d[i + 1], d[i + 2]) < OSCURO) continue;
    etiquetas[p] = cercano(grupos, [d[i], d[i + 1], d[i + 2]]);
  }

  // Filtro de mayoría 5×5: los píxeles de transición entre dos colores caían en un tercer
  // grupo y dejaban motas; cada píxel toma el grupo que domina a su alrededor
  const filtradas = new Int8Array(etiquetas);
  const conteo = new Uint8Array(grupos.length);
  for (let y = 2; y < H - 2; y++) {
    for (let x = 2; x < W - 2; x++) {
      const p = y * W + x;
      if (etiquetas[p] < 0) continue;
      conteo.fill(0);
      for (let dy = -2; dy <= 2; dy++) {
        for (let dx = -2; dx <= 2; dx++) {
          const e = etiquetas[p + dy * W + dx];
          if (e >= 0) conteo[e]++;
        }
      }
      let mejor = etiquetas[p];
      for (let k = 0; k < conteo.length; k++) if (conteo[k] > conteo[mejor]) mejor = k;
      filtradas[p] = mejor;
    }
  }

  for (let p = 0; p < W * H; p++) {
    const g = filtradas[p];
    if (g < 0) continue;
    const i = p * 4;
    // conserva el oscurecimiento de los bordes suavizados hacia el contorno
    const f = Math.min(1.1, lum(d[i], d[i + 1], d[i + 2]) / Math.max(1, lumGrupo[g]));
    const c = destino[g % destino.length];
    d[i] = c[0] * f; d[i + 1] = c[1] * f; d[i + 2] = c[2] * f;
  }
  return salida;
}

export function rotarTono(original, grados) {
  const salida = new ImageData(new Uint8ClampedArray(original.data), original.width, original.height);
  const d = salida.data;
  for (let i = 0; i < d.length; i += 4) {
    if (d[i + 3] === 0) continue;
    const [h, s, l] = rgbAHsl(d[i], d[i + 1], d[i + 2]);
    const [r, g, b] = hslARgb((h + grados / 360 + 1) % 1, s, l);
    d[i] = r; d[i + 1] = g; d[i + 2] = b;
  }
  return salida;
}

function rgbAHsl(r, g, b) {
  r /= 255; g /= 255; b /= 255;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const l = (max + min) / 2;
  if (max === min) return [0, 0, l];
  const d = max - min;
  const s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
  let h;
  if (max === r) h = (g - b) / d + (g < b ? 6 : 0);
  else if (max === g) h = (b - r) / d + 2;
  else h = (r - g) / d + 4;
  return [h / 6, s, l];
}

function hslARgb(h, s, l) {
  if (s === 0) return [l * 255, l * 255, l * 255];
  const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
  const p = 2 * l - q;
  const canal = (t) => {
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < 1 / 6) return p + (q - p) * 6 * t;
    if (t < 1 / 2) return q;
    if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
    return p;
  };
  return [canal(h + 1 / 3) * 255, canal(h) * 255, canal(h - 1 / 3) * 255];
}
