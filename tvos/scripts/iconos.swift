// Genera el ícono en capas (parallax) y las imágenes de Top Shelf de tvOS a partir de los assets del sitio.
// Uso: swift scripts/iconos.swift   (desde tvos/)
import AppKit

let raiz = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = raiz.appending(path: "../assets")
let catalogo = raiz.appending(path: "Alebrijes/Resources/Assets.xcassets/App Icon & Top Shelf Image.brandassets")

let ink = NSColor(red: 0x1a / 255, green: 0, blue: 0x33 / 255, alpha: 1)
let cenefa: [UInt32] = [0xff2e9a, 0xffd000, 0x00d98a, 0x00c2ff, 0xff7a00, 0x7b2ff7]
func color(_ hex: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: a)
}

func png(_ w: Int, _ h: Int, opaco: Bool, _ dibujar: (CGContext, CGFloat, CGFloat) -> Void) -> Data {
    // La capa de atrás no debe tener transparencia: se dibuja en un contexto sin alfa.
    // (Un NSBitmapImageRep de 3 canales como destino de dibujo no funciona: queda negro.)
    let alfa: CGImageAlphaInfo = opaco ? .noneSkipLast : .premultipliedLast
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: alfa.rawValue)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    dibujar(ctx, CGFloat(w), CGFloat(h))
    NSGraphicsContext.restoreGraphicsState()
    let datos = NSMutableData()
    let destino = CGImageDestinationCreateWithData(datos, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(destino, ctx.makeImage()!, nil)
    CGImageDestinationFinalize(destino)
    return datos as Data
}

// Fondo: tinta con manchas de color y cenefa abajo y arriba, como el sitio
func fondo(_ ctx: CGContext, _ w: CGFloat, _ h: CGFloat) {
    ctx.setFillColor(ink.cgColor)
    ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
    let r = max(w, h)
    for (hex, a, x, y, radio) in [(cenefa[0], 0.55, 0.2, 0.75, 0.5), (cenefa[3], 0.5, 0.85, 0.7, 0.5), (cenefa[1], 0.45, 0.5, 0.0, 0.55)] {
        let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                           colors: [color(hex, a).cgColor, color(hex, 0).cgColor] as CFArray, locations: [0, 1])!
        ctx.drawRadialGradient(g, startCenter: CGPoint(x: w * x, y: h * y), startRadius: 0,
                               endCenter: CGPoint(x: w * x, y: h * y), endRadius: r * radio, options: [])
    }
    let alto = h * 0.05
    let ancho = alto * 2.2
    var x: CGFloat = 0
    var i = 0
    while x < w {
        ctx.setFillColor(color(cenefa[i % cenefa.count]).cgColor)
        ctx.fill(CGRect(x: x, y: 0, width: ancho, height: alto))
        ctx.fill(CGRect(x: x, y: h - alto, width: ancho, height: alto))
        x += ancho
        i += 1
    }
}

func imagen(_ ruta: String, en ctx: CGContext, rect: CGRect) {
    let img = NSImage(contentsOf: assets.appending(path: ruta))!
    var r = rect
    let cg = img.cgImage(forProposedRect: &r, context: nil, hints: nil)!
    ctx.interpolationQuality = .high
    ctx.draw(cg, in: rect)
}

func texto(_ s: String, en ctx: CGContext, centro: CGPoint, alto: CGFloat) {
    let fuente = NSFont.systemFont(ofSize: alto, weight: .heavy)
    let redonda = NSFont(descriptor: fuente.fontDescriptor.withDesign(.rounded)!, size: alto)!
    let attrs: [NSAttributedString.Key: Any] = [
        .font: redonda, .foregroundColor: color(0xffd000),
        .strokeColor: ink, .strokeWidth: -6,
    ]
    let a = NSAttributedString(string: s, attributes: attrs)
    let t = a.size()
    a.draw(at: CGPoint(x: centro.x - t.width / 2, y: centro.y - t.height / 2))
}

func escribir(_ datos: Data, _ ruta: String) {
    let url = catalogo.appending(path: ruta)
    try! FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try! datos.write(to: url)
}

func json(_ obj: Any, _ ruta: String) {
    escribir(try! JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]), ruta + "/Contents.json")
}

let info = ["author": "xcode", "version": 1] as [String: Any]
// Don Pedro lo genera Codex ($alebrije-assets, references/icono.md); mientras no exista, un alebrije
let criatura = FileManager.default.fileExists(atPath: assets.appending(path: "icono/don-pedro.png").path)
    ? "icono/don-pedro.png" : "mezclas/jaguar-mariposa.png"

// Ícono: dos capas, fondo y criatura, para el efecto parallax al enfocar
func pila(_ nombre: String, _ w: Int, _ h: Int, escalas: [Int], idiom: String) {
    for (capa, opaco) in [("Back", true), ("Front", false)] {
        var imagenes: [[String: String]] = []
        for e in escalas {
            let archivo = "\(capa.lowercased())@\(e)x.png"
            let datos = png(w * e, h * e, opaco: opaco) { ctx, W, H in
                if opaco { fondo(ctx, W, H) } else {
                    let lado = H * 0.86
                    imagen(criatura, en: ctx, rect: CGRect(x: (W - lado) / 2, y: (H - lado) / 2, width: lado, height: lado))
                }
            }
            escribir(datos, "\(nombre).imagestack/\(capa).imagestacklayer/Content.imageset/\(archivo)")
            imagenes.append(["idiom": idiom, "scale": "\(e)x", "filename": archivo])
        }
        json(["images": imagenes, "info": info], "\(nombre).imagestack/\(capa).imagestacklayer/Content.imageset")
        json(["info": info], "\(nombre).imagestack/\(capa).imagestacklayer")
    }
    json(["info": info, "layers": [["filename": "Front.imagestacklayer"], ["filename": "Back.imagestacklayer"]]],
         "\(nombre).imagestack")
}

// Top Shelf: lo que se ve en la fila de arriba de la pantalla de inicio cuando la app está ahí
func estante(_ nombre: String, _ w: Int, _ h: Int) {
    var imagenes: [[String: String]] = []
    for e in [1, 2] {
        let archivo = "estante@\(e)x.png"
        let datos = png(w * e, h * e, opaco: true) { ctx, W, H in
            fondo(ctx, W, H)
            let lado = H * 0.8
            let animales = ["mezclas/ajolote-tucan.png", "mezclas/jaguar-mariposa.png", "mezclas/perro-tortuga.png"]
            for (i, ruta) in animales.enumerated() {
                let x = W * (i == 0 ? 0.14 : i == 1 ? 0.5 : 0.86) - lado / 2
                imagen(ruta, en: ctx, rect: CGRect(x: x, y: (H - lado) / 2, width: lado, height: lado))
            }
            texto("¡Alebrijes!", en: ctx, centro: CGPoint(x: W / 2, y: H * 0.88), alto: H * 0.14) // CoreGraphics: y crece hacia arriba
        }
        escribir(datos, "\(nombre).imageset/\(archivo)")
        imagenes.append(["idiom": "tv", "scale": "\(e)x", "filename": archivo])
    }
    json(["images": imagenes, "info": info], "\(nombre).imageset")
}

try? FileManager.default.removeItem(at: catalogo)
pila("App Icon", 400, 240, escalas: [1, 2], idiom: "tv")
pila("App Icon - App Store", 1280, 768, escalas: [1], idiom: "tv")
estante("Top Shelf Image", 1920, 720)
estante("Top Shelf Image Wide", 2320, 720)
json([
    "assets": [
        ["filename": "App Icon - App Store.imagestack", "idiom": "tv", "role": "primary-app-icon", "size": "1280x768"],
        ["filename": "App Icon.imagestack", "idiom": "tv", "role": "primary-app-icon", "size": "400x240"],
        ["filename": "Top Shelf Image Wide.imageset", "idiom": "tv", "role": "top-shelf-image-wide", "size": "2320x720"],
        ["filename": "Top Shelf Image.imageset", "idiom": "tv", "role": "top-shelf-image", "size": "1920x720"],
    ],
    "info": info,
], "")
json(["info": info], "..")
print("Íconos generados en \(catalogo.path)")
