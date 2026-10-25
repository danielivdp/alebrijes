import SwiftUI

struct Inicio: View {
    @Binding var ruta: [Pantalla]

    var body: some View {
        VStack(spacing: 50) {
            VStack(spacing: 10) {
                Text("¡Alebrijes!")
                    .font(Tema.letra(150, .heavy))
                    .foregroundStyle(
                        LinearGradient(colors: [Tema.pink, Tema.yellow, Tema.green, Tema.blue, Tema.purple],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(color: Tema.ink, radius: 0, x: 6, y: 6)
                Text("Criaturas fantásticas del arte popular mexicano, nacidas de un sueño.")
                    .font(Tema.letra(38, .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }

            HStack(spacing: 70) {
                Tarjeta(icono: "📖", titulo: "El cuento",
                        texto: "Diez páginas sobre Don Pedro Linares, el sueño que tuvo en 1936 y cómo los alebrijes llegaron a todo México.",
                        ir: "Leer el cuento →", color: Tema.pink) { ruta.append(.cuento) }
                Tarjeta(icono: "🎡", titulo: "Crea tu alebrije",
                        texto: "Gira las ruletas, mezcla dos animales y descubre el nombre y los colores de tu propia criatura.",
                        ir: "¡A jugar! →", color: Tema.blue) { ruta.append(.crear) }
            }

            Button("Fuentes y licencias") { ruta.append(.creditos) }
                .buttonStyle(BotonAlebrije(fondo: .white, sombra: Tema.blue, tamano: 28))
        }
        .padding(60)
    }
}

private struct Tarjeta: View {
    let icono: String
    let titulo: String
    let texto: String
    let ir: String
    let color: Color
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            Cuerpo(icono: icono, titulo: titulo, texto: texto, ir: ir, color: color)
        }
        .buttonStyle(SinEfecto())
    }

    private struct Cuerpo: View {
        let icono: String
        let titulo: String
        let texto: String
        let ir: String
        let color: Color
        @Environment(\.isFocused) private var enfocado

        var body: some View {
            Papel(sombra: color) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(icono).font(.system(size: 90))
                    Text(titulo).font(Tema.letra(58, .heavy))
                    Text(texto).font(Tema.letra(30, .regular)).fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Text(ir).font(Tema.letra(34)).foregroundStyle(Tema.purple)
                }
                .padding(44)
                .frame(width: 640, height: 500, alignment: .topLeading)
            }
            .scaleEffect(enfocado ? 1.08 : 1)
            .rotationEffect(.degrees(enfocado ? -1 : 0))
            .shadow(color: enfocado ? color.opacity(0.7) : .clear, radius: 40)
            .animation(.spring(duration: 0.3, bounce: 0.4), value: enfocado)
        }
    }
}
