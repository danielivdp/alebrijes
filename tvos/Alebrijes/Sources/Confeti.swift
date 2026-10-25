import SwiftUI

// Port de js/confeti.js: banderitas de papel picado y flores de cempasúchil.
struct Confeti: View {
    var duracion: Double = 4.5

    @Environment(\.accessibilityReduceMotion) private var sinMovimiento
    @State private var inicio = Date.now
    @State private var piezas: [Pieza] = []

    private struct Pieza {
        let x: Double, y: Double, vy: Double, fase: Double, giro: Double, rot: Double, tam: Double
        let color: Color
        let flor: Bool
    }

    var body: some View {
        if !sinMovimiento {
            TimelineView(.animation) { linea in
                Canvas { ctx, size in
                    if piezas.isEmpty { return }
                    let pasado = linea.date.timeIntervalSince(inicio)
                    guard pasado < duracion else { return }
                    let cuadros = pasado * 60 // el original mueve por cuadro a 60 fps
                    ctx.opacity = min(1, max(0, (duracion - pasado) / 0.8))
                    for p in piezas {
                        var c = ctx
                        c.translateBy(x: p.x * size.width + sin(p.fase + pasado * 1000 / 400) * 1.2 * 20,
                                      y: p.y * size.height + p.vy * cuadros)
                        c.rotate(by: .radians(p.rot + p.giro * cuadros))
                        if p.flor { flor(c, r: p.tam * 0.6) } else { banderita(c, t: p.tam, color: p.color) }
                    }
                }
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()
            .onAppear(perform: lanzar)
        }
    }

    private func lanzar() {
        inicio = .now
        piezas = (0..<170).map { _ in
            Pieza(x: .random(in: 0...1), y: -0.02 - .random(in: 0...0.6), vy: 4 + .random(in: 0...6),
                  fase: .random(in: 0...(2 * .pi)), giro: .random(in: -0.06...0.06), rot: .random(in: 0...(2 * .pi)),
                  tam: 24 + .random(in: 0...26), color: Tema.cenefa.randomElement()!, flor: .random(in: 0...1) < 0.22)
        }
    }

    private func banderita(_ ctx: GraphicsContext, t: Double, color: Color) {
        let w = t, h = t * 1.2
        var p = Path()
        p.move(to: CGPoint(x: -w / 2, y: -h / 2))
        p.addLine(to: CGPoint(x: w / 2, y: -h / 2))
        p.addLine(to: CGPoint(x: w / 2, y: h / 2))
        // borde inferior en picos, como el papel picado
        let picos = 4
        for i in stride(from: picos, through: 0, by: -1) {
            p.addLine(to: CGPoint(x: -w / 2 + w * Double(i) / Double(picos), y: i % 2 == 1 ? h / 2 - t * 0.22 : h / 2))
        }
        p.closeSubpath()
        ctx.fill(p, with: .color(color))
        // calado al centro
        var calado = Path()
        calado.move(to: CGPoint(x: 0, y: -h * 0.22))
        calado.addLine(to: CGPoint(x: w * 0.18, y: 0))
        calado.addLine(to: CGPoint(x: 0, y: h * 0.22))
        calado.addLine(to: CGPoint(x: -w * 0.18, y: 0))
        calado.closeSubpath()
        ctx.fill(calado, with: .color(.white.opacity(0.75)))
    }

    private func flor(_ ctx: GraphicsContext, r: Double) {
        for i in 0..<8 {
            var c = ctx
            let a = Double(i) * .pi / 4
            c.translateBy(x: cos(a) * r * 0.55, y: sin(a) * r * 0.55)
            c.rotate(by: .radians(a))
            c.fill(Path(ellipseIn: CGRect(x: -r * 0.45, y: -r * 0.3, width: r * 0.9, height: r * 0.6)),
                   with: .color(Color(hex: 0xff8c00)))
        }
        ctx.fill(Path(ellipseIn: CGRect(x: -r * 0.4, y: -r * 0.4, width: r * 0.8, height: r * 0.8)),
                 with: .color(Color(hex: 0xffc400)))
    }
}
