import SwiftUI

// Mismos colores que css/sitio.css
enum Tema {
    static let pink = Color(hex: 0xff2e9a)
    static let purple = Color(hex: 0x7b2ff7)
    static let blue = Color(hex: 0x00c2ff)
    static let green = Color(hex: 0x00d98a)
    static let yellow = Color(hex: 0xffd000)
    static let orange = Color(hex: 0xff7a00)
    static let ink = Color(hex: 0x1a0033)
    static let paper = Color(hex: 0xfff8ec)
    static let paperInk = Color(hex: 0x2a1440)
    static let radio: CGFloat = 36

    static let cenefa = [pink, yellow, green, blue, orange, purple]

    // SF Rounded en lugar de Fredoka/Baloo: viene con el sistema y se parece
    static func letra(_ tamano: CGFloat, _ peso: Font.Weight = .bold) -> Font {
        .system(size: tamano, weight: peso, design: .rounded)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255
        )
    }
}

/// Fondo oscuro con manchas de color y cenefa arriba y abajo, como el body del sitio.
struct Fondo: View {
    var body: some View {
        ZStack {
            Tema.ink
            GeometryReader { geo in
                let r = max(geo.size.width, geo.size.height)
                ZStack {
                    mancha(Tema.pink.opacity(0.45), en: UnitPoint(x: 0.2, y: 0.2), radio: r * 0.4)
                    mancha(Tema.blue.opacity(0.4), en: UnitPoint(x: 0.8, y: 0.3), radio: r * 0.45)
                    mancha(Tema.yellow.opacity(0.35), en: UnitPoint(x: 0.5, y: 0.95), radio: r * 0.45)
                }
            }
            VStack {
                Cenefa()
                Spacer()
                Cenefa()
            }
        }
        .ignoresSafeArea()
    }

    private func mancha(_ color: Color, en centro: UnitPoint, radio: CGFloat) -> some View {
        RadialGradient(colors: [color, .clear], center: centro, startRadius: 0, endRadius: radio)
    }
}

struct Cenefa: View {
    var alto: CGFloat = 20

    var body: some View {
        Canvas { ctx, size in
            let ancho: CGFloat = 45
            var x: CGFloat = 0
            var i = 0
            while x < size.width {
                ctx.fill(Path(CGRect(x: x, y: 0, width: ancho, height: size.height)),
                         with: .color(Tema.cenefa[i % Tema.cenefa.count]))
                x += ancho
                i += 1
            }
        }
        .frame(height: alto)
    }
}

/// Botón amarillo con borde de tinta y sombra rosa desplazada. Con el foco crece y se levanta.
struct BotonAlebrije: ButtonStyle {
    var fondo: Color = Tema.yellow
    var sombra: Color = Tema.pink
    var tamano: CGFloat = 40

    func makeBody(configuration: Configuration) -> some View {
        Cuerpo(configuration: configuration, estilo: self)
    }

    private struct Cuerpo: View {
        let configuration: Configuration
        let estilo: BotonAlebrije
        @Environment(\.isFocused) private var enfocado

        var body: some View {
            let desplazo: CGFloat = enfocado ? 10 : 6
            configuration.label
                .font(Tema.letra(estilo.tamano))
                .foregroundStyle(Tema.ink)
                .padding(.horizontal, estilo.tamano * 1.4)
                .padding(.vertical, estilo.tamano * 0.5)
                .background(Capsule().fill(estilo.fondo).brightness(enfocado ? 0 : -0.15))
                .overlay(Capsule().stroke(Tema.ink, lineWidth: 5))
                // va después: cada .background se dibuja detrás del anterior
                .background(Capsule().fill(estilo.sombra).offset(x: desplazo, y: desplazo))
                .overlay(Capsule().stroke(Tema.green, lineWidth: enfocado ? 6 : 0).padding(-12))
                .scaleEffect(configuration.isPressed ? 0.95 : enfocado ? 1.1 : 1)
                .animation(.spring(duration: 0.25, bounce: 0.4), value: enfocado)
                .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
        }
    }
}

/// Sin ningún efecto de foco: para vistas que manejan el foco por su cuenta (el libro del cuento).
struct SinEfecto: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

/// Tarjeta de papel con sombra de color, como las de la portada.
struct Papel<Contenido: View>: View {
    var sombra: Color = Tema.purple
    @ViewBuilder var contenido: Contenido

    var body: some View {
        contenido
            .foregroundStyle(Tema.paperInk)
            .background(Tema.paper)
            .clipShape(RoundedRectangle(cornerRadius: Tema.radio))
            .overlay(RoundedRectangle(cornerRadius: Tema.radio).stroke(Tema.ink, lineWidth: 6))
            .background(RoundedRectangle(cornerRadius: Tema.radio).fill(sombra).offset(x: 14, y: 14))
    }
}

/// Tira de papel picado para lo alto de las tarjetas.
struct Picado: View {
    var body: some View {
        Canvas { ctx, size in
            let ancho: CGFloat = 60
            var x: CGFloat = 0
            var i = 0
            while x < size.width {
                // bandera con borde inferior en pico y un calado al centro
                var p = Path()
                p.move(to: CGPoint(x: x, y: 0))
                p.addLine(to: CGPoint(x: x + ancho, y: 0))
                p.addLine(to: CGPoint(x: x + ancho, y: size.height))
                p.addLine(to: CGPoint(x: x + ancho / 2, y: size.height * 0.7))
                p.addLine(to: CGPoint(x: x, y: size.height))
                p.closeSubpath()
                ctx.fill(p, with: .color(Tema.cenefa[i % Tema.cenefa.count]))
                let c = CGRect(x: x + ancho / 2 - 9, y: size.height * 0.25, width: 18, height: 18)
                ctx.fill(Path(ellipseIn: c), with: .color(Tema.paper))
                x += ancho
                i += 1
            }
        }
        .frame(height: 60)
    }
}
