import SwiftUI

// Port de js/ruleta.js. La flecha está arriba; girar(a:) deja el segmento i bajo la flecha.
struct Segmento {
    let etiqueta: String
    var emoji: String? = nil
    let color: Color
}

struct RuletaView: View {
    let segmentos: [Segmento]
    let giro: Double
    var medalla: UIImage? = nil

    var body: some View {
        GeometryReader { geo in
            let lado = min(geo.size.width, geo.size.height)
            ZStack(alignment: .top) {
                rueda
                    .rotationEffect(.degrees(giro))
                    .shadow(color: Tema.yellow.opacity(0.5), radius: 30)
                if let medalla {
                    Image(uiImage: medalla)
                        .resizable().scaledToFit()
                        // el cuadrado de la imagen debe caber dentro del círculo: lado = diámetro / √2
                        .padding(lado * 0.76 * 0.15)
                        .frame(width: lado * 0.76, height: lado * 0.76)
                        .background(Circle().fill(Tema.paper))
                        .overlay(Circle().stroke(Tema.ink, lineWidth: 8))
                        .background(Circle().stroke(Tema.yellow, lineWidth: 24))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.scale(scale: 0).combined(with: .opacity))
                }
                Flecha()
                    .fill(.white)
                    .shadow(color: Tema.ink, radius: 0, y: 3)
                    .frame(width: lado * 0.12, height: lado * 0.11)
                    .offset(y: -lado * 0.03)
            }
            .frame(width: lado, height: lado)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var rueda: some View {
        Canvas { ctx, size in
            // mismas coordenadas que el viewBox del SVG: -110…110
            let s = min(size.width, size.height) / 220
            ctx.translateBy(x: size.width / 2, y: size.height / 2)
            ctx.scaleBy(x: s, y: s)
            let paso = 360 / Double(segmentos.count)

            for (i, seg) in segmentos.enumerated() {
                let a0 = Angle.degrees(Double(i) * paso - 90)
                let a1 = Angle.degrees(Double(i + 1) * paso - 90)
                var p = Path()
                p.move(to: .zero)
                p.addArc(center: .zero, radius: 100, startAngle: a0, endAngle: a1, clockwise: false)
                p.closeSubpath()
                ctx.fill(p, with: .color(seg.color))
                ctx.stroke(p, with: .color(Tema.ink), lineWidth: 3)

                let medio = Double(i) * paso + paso / 2
                var c = ctx
                c.rotate(by: .degrees(medio))
                c.translateBy(x: 0, y: -66)
                if let emoji = seg.emoji {
                    c.rotate(by: .degrees(-medio))
                    c.draw(Text(emoji).font(.system(size: 30)), at: .zero)
                } else {
                    c.draw(Text(seg.etiqueta).font(Tema.letra(15)).foregroundStyle(Tema.ink), at: .zero)
                }
            }

            ctx.fill(Path(ellipseIn: CGRect(x: -14, y: -14, width: 28, height: 28)), with: .color(.white))
            ctx.stroke(Path(ellipseIn: CGRect(x: -14, y: -14, width: 28, height: 28)), with: .color(Tema.ink), lineWidth: 4)
            ctx.stroke(Path(ellipseIn: CGRect(x: -104, y: -104, width: 208, height: 208)), with: .color(Tema.ink), lineWidth: 8)
        }
    }

    /// Giro acumulado que deja el segmento `indice` bajo la flecha, tras cinco vueltas completas.
    static func giro(desde actual: Double, hacia indice: Int, de total: Int) -> Double {
        let paso = 360 / Double(total)
        let destino = 360 - (Double(indice) * paso + paso / 2)
        let ahora = (actual.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        return actual + 360 * 5 + (destino - ahora + 360).truncatingRemainder(dividingBy: 360)
    }
}

private struct Flecha: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}
