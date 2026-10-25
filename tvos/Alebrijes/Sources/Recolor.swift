import CoreGraphics
import UIKit

// Port de js/recolor.js: recoloreo de imágenes con colores planos y contorno negro.
// Agrupa los colores de la imagen (k-means) y cambia cada grupo por un color de la paleta.

/// Píxeles RGBA sin premultiplicar, como el ImageData del canvas.
struct Pixeles: Sendable {
    var datos: [UInt8]
    let ancho: Int
    let alto: Int

    init?(_ imagen: UIImage, lado: Int = 1024) {
        guard let cg = imagen.cgImage else { return nil }
        ancho = lado
        alto = lado
        var premult = [UInt8](repeating: 0, count: lado * lado * 4)
        let ok = premult.withUnsafeMutableBytes { buf -> Bool in
            guard let ctx = CGContext(data: buf.baseAddress, width: lado, height: lado, bitsPerComponent: 8,
                                      bytesPerRow: lado * 4, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: lado, height: lado))
            return true
        }
        guard ok else { return nil }
        // CoreGraphics solo dibuja premultiplicado; se deshace para que los cálculos sean los del canvas
        for i in stride(from: 0, to: premult.count, by: 4) {
            let a = Int(premult[i + 3])
            if a > 0 && a < 255 {
                for c in 0..<3 { premult[i + c] = UInt8(min(255, Int(premult[i + c]) * 255 / a)) }
            }
        }
        datos = premult
    }

    func imagen() -> UIImage? {
        var premult = datos
        for i in stride(from: 0, to: premult.count, by: 4) {
            let a = Int(premult[i + 3])
            if a < 255 {
                for c in 0..<3 { premult[i + c] = UInt8(Int(premult[i + c]) * a / 255) }
            }
        }
        guard let proveedor = CGDataProvider(data: Data(premult) as CFData),
              let cg = CGImage(width: ancho, height: alto, bitsPerComponent: 8, bitsPerPixel: 32,
                               bytesPerRow: ancho * 4, space: CGColorSpaceCreateDeviceRGB(),
                               bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                               provider: proveedor, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        else { return nil }
        return UIImage(cgImage: cg)
    }
}

enum Recolor {
    typealias RGB = SIMD3<Double>

    static let oscuro = 60.0 // luminancia por debajo de la cual un píxel es contorno y no se toca

    static func lum(_ c: RGB) -> Double { 0.299 * c.x + 0.587 * c.y + 0.114 * c.z }

    static func rgb(_ hex: UInt32) -> RGB {
        RGB(Double((hex >> 16) & 255), Double((hex >> 8) & 255), Double(hex & 255))
    }

    static func agrupar(_ img: Pixeles, k: Int = 6) -> [RGB] {
        let d = img.datos
        var muestras: [RGB] = []
        let salto = max(1, d.count / 4 / 20000)
        for i in stride(from: 0, to: d.count, by: 4 * salto) {
            let c = RGB(Double(d[i]), Double(d[i + 1]), Double(d[i + 2]))
            if d[i + 3] < 128 || lum(c) < oscuro { continue }
            muestras.append(c)
        }
        guard let primera = muestras.first else { return [] }

        // Inicialización por punto más lejano: centros bien separados
        var centros = [primera]
        while centros.count < k {
            var mejor = primera
            var mejorDist = -1.0
            for m in muestras {
                let dist = centros.map { dist2($0, m) }.min()!
                if dist > mejorDist { mejorDist = dist; mejor = m }
            }
            if mejorDist == 0 { break }
            centros.append(mejor)
        }

        var conteos: [Int] = []
        for _ in 0..<10 {
            var sumas = [RGB](repeating: .zero, count: centros.count)
            conteos = [Int](repeating: 0, count: centros.count)
            for m in muestras {
                let c = cercano(centros, m)
                sumas[c] += m
                conteos[c] += 1
            }
            for i in centros.indices where conteos[i] > 0 {
                centros[i] = sumas[i] / Double(conteos[i])
            }
        }
        // Grupos más grandes primero: reciben los primeros colores de la paleta
        return zip(centros, conteos).sorted { $0.1 > $1.1 }.map(\.0)
    }

    static func aplicarPaleta(_ original: Pixeles, grupos: [RGB], colores: [UInt32]) -> Pixeles {
        var salida = original
        let destino = colores.map(rgb)
        let lumGrupo = grupos.map(lum)
        salida.datos.withUnsafeMutableBufferPointer { d in
            for i in stride(from: 0, to: d.count, by: 4) {
                if d[i + 3] == 0 { continue }
                let p = RGB(Double(d[i]), Double(d[i + 1]), Double(d[i + 2]))
                let l = lum(p)
                if l < oscuro { continue }
                let g = cercano(grupos, p)
                // conserva el oscurecimiento de los bordes suavizados hacia el contorno
                let f = min(1.15, l / max(1, lumGrupo[g]))
                let c = destino[g % destino.count] * f
                d[i] = byte(c.x); d[i + 1] = byte(c.y); d[i + 2] = byte(c.z)
            }
        }
        return salida
    }

    static func rotarTono(_ original: Pixeles, grados: Double) -> Pixeles {
        var salida = original
        salida.datos.withUnsafeMutableBufferPointer { d in
            for i in stride(from: 0, to: d.count, by: 4) {
                if d[i + 3] == 0 { continue }
                let (h, s, l) = rgbAHsl(Double(d[i]), Double(d[i + 1]), Double(d[i + 2]))
                let c = hslARgb((h + grados / 360 + 1).truncatingRemainder(dividingBy: 1), s, l)
                d[i] = byte(c.x); d[i + 1] = byte(c.y); d[i + 2] = byte(c.z)
            }
        }
        return salida
    }

    private static func byte(_ v: Double) -> UInt8 { UInt8(max(0, min(255, v))) }

    private static func dist2(_ a: RGB, _ b: RGB) -> Double {
        let d = a - b
        return (d * d).sum()
    }

    private static func cercano(_ centros: [RGB], _ p: RGB) -> Int {
        var mejor = 0
        var mejorDist = Double.infinity
        for i in centros.indices {
            let dd = dist2(centros[i], p)
            if dd < mejorDist { mejorDist = dd; mejor = i }
        }
        return mejor
    }

    private static func rgbAHsl(_ r: Double, _ g: Double, _ b: Double) -> (Double, Double, Double) {
        let r = r / 255, g = g / 255, b = b / 255
        let mx = max(r, g, b), mn = min(r, g, b)
        let l = (mx + mn) / 2
        if mx == mn { return (0, 0, l) }
        let d = mx - mn
        let s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn)
        var h: Double
        if mx == r { h = (g - b) / d + (g < b ? 6 : 0) }
        else if mx == g { h = (b - r) / d + 2 }
        else { h = (r - g) / d + 4 }
        h /= 6
        return (h, s, l)
    }

    private static func hslARgb(_ h: Double, _ s: Double, _ l: Double) -> RGB {
        if s == 0 { return RGB(repeating: l * 255) }
        let q = l < 0.5 ? l * (1 + s) : l + s - l * s
        let p = 2 * l - q
        func canal(_ t: Double) -> Double {
            var t = t
            if t < 0 { t += 1 }
            if t > 1 { t -= 1 }
            if t < 1.0 / 6 { return p + (q - p) * 6 * t }
            if t < 1.0 / 2 { return q }
            if t < 2.0 / 3 { return p + (q - p) * (2.0 / 3 - t) * 6 }
            return p
        }
        return RGB(canal(h + 1.0 / 3), canal(h), canal(h - 1.0 / 3)) * 255
    }
}
