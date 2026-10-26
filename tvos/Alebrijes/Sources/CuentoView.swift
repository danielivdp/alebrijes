import AVFoundation
import SwiftUI

/// El libro entero es un solo elemento enfocable: ◀ ▶ cambian de página, el botón central avanza
/// y ⏯ lee la página en voz alta. Así un niño no tiene que buscar botones con el foco.
struct CuentoView: View {
    let alTerminar: () -> Void

    // `-pagina N` abre directo en esa página, para capturas en el simulador
    @State private var actual = max(0, min(paginas.count - 1, UserDefaults.standard.integer(forKey: "pagina") - 1))
    @State private var haciaAdelante = true
    @State private var voz = AVSpeechSynthesizer()

    private var pagina: Pagina { paginas[actual] }
    private var esUltima: Bool { actual == paginas.count - 1 }

    var body: some View {
        VStack(spacing: 36) {
            Button {
                if esUltima { alTerminar() } else { mostrar(actual + 1) }
            } label: {
                libro
            }
            .buttonStyle(SinEfecto())
            .onMoveCommand { direccion in
                switch direccion {
                case .left: mostrar(actual - 1)
                case .right: mostrar(actual + 1)
                default: break
                }
            }
            .onPlayPauseCommand(perform: leer)

            HStack(spacing: 18) {
                ForEach(paginas.indices, id: \.self) { i in
                    Circle()
                        .fill(i == actual ? Tema.yellow : .clear)
                        .stroke(i == actual ? Tema.yellow : .white, lineWidth: 3)
                        .frame(width: 22, height: 22)
                        .scaleEffect(i == actual ? 1.3 : 1)
                }
            }

            Text("◀ ▶ cambiar de página   ·   ⏯ escuchar el cuento")
                .font(Tema.letra(26, .medium))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 80)
        .onDisappear { voz.stopSpeaking(at: .immediate) }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var libro: some View {
        Papel {
            HStack(spacing: 0) {
                // imagen y texto mitad y mitad, como en la web
                lamina
                    .frame(width: 840, height: 560)
                    .clipped()
                VStack(alignment: .leading, spacing: 20) {
                    Text("PÁGINA \(actual + 1) DE \(paginas.count)")
                        .font(Tema.letra(24))
                        .tracking(2)
                        .foregroundStyle(Tema.pink)
                    Text(pagina.titulo)
                        .font(Tema.letra(56, .heavy))
                        .fixedSize(horizontal: false, vertical: true)
                    // el tamaño de letra más grande con el que cabe la página entera
                    ViewThatFits(in: .vertical) {
                        parrafos(46)
                        parrafos(40)
                        parrafos(34)
                        parrafos(30)
                        parrafos(27)
                        parrafos(24)
                    }
                    Spacer(minLength: 0)
                    if esUltima {
                        Text("Presiona el botón para 🎡 crear tu alebrije")
                            .font(Tema.letra(30))
                            .foregroundStyle(Tema.purple)
                    }
                }
                .padding(44)
                .frame(width: 820, height: 680, alignment: .topLeading)
            }
        }
        .id(actual)
        .transition(.asymmetric(
            insertion: .move(edge: haciaAdelante ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: haciaAdelante ? .leading : .trailing).combined(with: .opacity)
        ))
    }

    private func parrafos(_ tamano: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: tamano * 0.6) {
            ForEach(pagina.texto, id: \.self) { parrafo in
                Text(parrafo)
                    .font(Tema.letra(tamano, .regular))
                    .lineSpacing(tamano * 0.2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var lamina: some View {
        if let img = Recursos.imagen(pagina.imagen) {
            ZStack(alignment: .bottomTrailing) {
                if pagina.foto != nil {
                    Tema.ink
                    Image(uiImage: img).resizable().scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Image(uiImage: img).resizable().scaledToFill()
                }
                if let foto = pagina.foto {
                    Text(foto.credito)
                        .font(Tema.letra(20, .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16).padding(.vertical, 6)
                        .background(Capsule().fill(Tema.ink.opacity(0.75)))
                        .padding(14)
                }
            }
        } else {
            ZStack {
                LinearGradient(colors: [Tema.yellow, Tema.pink, Tema.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                Text("Ilustración \(actual + 1) en camino ✏️")
                    .font(Tema.letra(30))
                    .padding(.horizontal, 24).padding(.vertical, 10)
                    .background(Capsule().fill(Tema.paper))
            }
        }
    }

    private func mostrar(_ indice: Int) {
        let nuevo = max(0, min(paginas.count - 1, indice))
        guard nuevo != actual else { return }
        voz.stopSpeaking(at: .immediate)
        haciaAdelante = nuevo > actual
        withAnimation(.spring(duration: 0.45, bounce: 0.15)) { actual = nuevo }
    }

    private func leer() {
        if voz.isSpeaking {
            voz.stopSpeaking(at: .immediate)
            return
        }
        let frase = AVSpeechUtterance(string: "\(pagina.titulo). \(pagina.texto.joined(separator: " "))")
        frase.voice = AVSpeechSynthesisVoice(language: "es-MX")
        frase.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        voz.speak(frase)
    }
}
