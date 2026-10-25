import SwiftUI

// Port de js/crear.js: un paso a la vez, solo se ve la ruleta del paso actual.
private let coloresRuleta: [Color] = [Tema.pink, Tema.yellow, Tema.green, Tema.blue, Tema.orange, Color(hex: 0xb58cff)]

private let pasos = [
    (titulo: "Paso 1 de 3 · Elige el primer animal", boton: "🎡 Girar"),
    (titulo: "Paso 2 de 3 · Elige el segundo animal", boton: "🎡 Girar"),
    (titulo: "Paso 3 de 3 · Elige los colores", boton: "🎨 Girar"),
]

private struct Mezcla: Sendable {
    let original: Pixeles
    let grupos: [Recolor.RGB]
}

@MainActor @Observable
final class Juego {
    enum Ventana { case nombre, alebrije }

    let animales = Recursos.animales
    var paso = 0
    var a: Animal?
    var b: Animal?
    var nombre: String?
    var elegido = ""
    var giros = [0.0, 0.0, 0.0]
    var medallas: [UIImage?] = [nil, nil]
    var ventana: Ventana?
    var alebrije: UIImage?
    private(set) var ocupado = false
    private var mezcla: Task<Mezcla?, Never>?

    var segmentosAnimales: [Segmento] {
        animales.enumerated().map { i, a in
            Segmento(etiqueta: a.nombre, emoji: a.emoji, color: coloresRuleta[i % coloresRuleta.count])
        }
    }

    var segmentosColores: [Segmento] {
        paletas.enumerated().map { i, p in
            if case let .lista(c) = p.colores { return Segmento(etiqueta: p.etiqueta, color: Color(hex: c[0])) }
            return Segmento(etiqueta: p.etiqueta, color: coloresRuleta[i])
        }
    }

    func reiniciar() {
        paso = 0
        a = nil
        b = nil
        nombre = nil
        elegido = ""
        medallas = [nil, nil]
        ventana = nil
        alebrije = nil
        mezcla?.cancel()
        mezcla = nil
    }

    func avanzar() async {
        guard !ocupado, ventana == nil else { return }
        ocupado = true
        defer { ocupado = false }
        switch paso {
        case 0: await girarAnimal(0, opciones: animales)
        // la ruleta B nunca cae en el animal de la A
        case 1: await girarAnimal(1, opciones: animales.filter { $0 != a })
        default: await girarColores()
        }
    }

    func aColores() {
        guard ventana == .nombre else { return }
        ventana = nil
        paso = 2
        elegido = ""
    }

    private func girarAnimal(_ lado: Int, opciones: [Animal]) async {
        guard let animal = opciones.randomElement(), let i = animales.firstIndex(of: animal) else { return }
        elegido = ""
        await girar(lado, hacia: i, de: animales.count)
        if lado == 0 { a = animal } else { b = animal }
        withAnimation(.spring(duration: 0.6, bounce: 0.5)) { medallas[lado] = animal.imagen }
        elegido = "¡\(animal.nombre)!"
        try? await Task.sleep(for: .seconds(1.4))

        if lado == 0 {
            paso = 1
            elegido = ""
            return
        }
        guard let a, let b else { return }
        nombre = a.inicio + b.fin
        // Se carga y analiza mientras el niño ve el nombre, para que revelar sea instantáneo
        let archivo = [a.slug, b.slug].sorted().joined(separator: "-")
        mezcla = Task.detached(priority: .userInitiated) {
            guard let img = Recursos.imagen("mezclas/\(archivo).png"), let px = Pixeles(img) else { return nil }
            return Mezcla(original: px, grupos: Recolor.agrupar(px))
        }
        ventana = .nombre
    }

    private func girarColores() async {
        let i = Int.random(in: 0..<paletas.count)
        let paleta = paletas[i]
        // el recoloreo corre mientras gira la ruleta
        let colores: Task<UIImage?, Never>? = mezcla.map { mezcla in
            Task.detached(priority: .userInitiated) {
                guard let m = await mezcla.value else { return nil }
                let px: Pixeles
                switch paleta.colores {
                case .original: px = m.original
                case .tono: px = Recolor.rotarTono(m.original, grados: Double(60 + Int.random(in: 0..<240)))
                case let .lista(c): px = Recolor.aplicarPaleta(m.original, grupos: m.grupos, colores: c.shuffled())
                }
                return px.imagen()
            }
        }
        await girar(2, hacia: i, de: paletas.count)
        elegido = "¡\(paleta.etiqueta)!"
        try? await Task.sleep(for: .seconds(0.9))
        alebrije = await colores?.value
        ventana = .alebrije
    }

    private func girar(_ ruleta: Int, hacia indice: Int, de total: Int) async {
        let destino = RuletaView.giro(desde: giros[ruleta], hacia: indice, de: total)
        await withCheckedContinuation { (fin: CheckedContinuation<Void, Never>) in
            withAnimation(.timingCurve(0.17, 0.85, 0.25, 1, duration: 3.2)) {
                giros[ruleta] = destino
            } completion: {
                fin.resume()
            }
        }
    }
}

struct CrearView: View {
    @State private var juego = Juego()
    @FocusState private var foco: Foco?

    private enum Foco { case accion, ventana }

    var body: some View {
        ZStack {
            escenario
                .disabled(juego.ventana != nil)

            if let ventana = juego.ventana {
                Tema.ink.opacity(0.78).ignoresSafeArea()
                Confeti()
                Group {
                    switch ventana {
                    case .nombre: tarjetaNombre
                    case .alebrije: tarjetaAlebrije
                    }
                }
                .transition(.scale(scale: 0.3).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.55, bounce: 0.4), value: juego.ventana)
        .onChange(of: juego.ventana) { _, ventana in
            foco = ventana == nil ? .accion : .ventana
        }
        // Menú en una ventana la cierra, como Esc en el sitio; sin ventana, regresa a la portada
        .onExitCommand(perform: salir)
        .onAppear {
            juego.reiniciar()
            foco = .accion
        }
        // `-demo N` juega solo hasta el paso N (1: nombre, 2: alebrije), para capturas en el simulador
        .task {
            let hasta = UserDefaults.standard.integer(forKey: "demo")
            guard hasta > 0 else { return }
            await juego.avanzar()
            await juego.avanzar()
            if hasta > 1 {
                juego.aColores()
                await juego.avanzar()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var escenario: some View {
        VStack(spacing: 24) {
            progreso
            Text(pasos[juego.paso].titulo)
                .font(Tema.letra(44, .heavy))
                .foregroundStyle(.white)

            ZStack {
                if juego.paso == 0 {
                    RuletaView(segmentos: juego.segmentosAnimales, giro: juego.giros[0], medalla: juego.medallas[0])
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                } else if juego.paso == 1 {
                    RuletaView(segmentos: juego.segmentosAnimales, giro: juego.giros[1], medalla: juego.medallas[1])
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                } else {
                    RuletaView(segmentos: juego.segmentosColores, giro: juego.giros[2])
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                }
            }
            .frame(height: 520)
            .animation(.spring(duration: 0.5, bounce: 0.4), value: juego.paso)

            Text(juego.elegido)
                .font(Tema.letra(54, .heavy))
                .foregroundStyle(Tema.yellow)
                .frame(height: 64)

            Button(pasos[juego.paso].boton) {
                Task { await juego.avanzar() }
            }
            .buttonStyle(BotonAlebrije(tamano: 44))
            .opacity(juego.ocupado ? 0.5 : 1)
            .focused($foco, equals: .accion)
        }
        .padding(.vertical, 30)
    }

    private var progreso: some View {
        HStack(spacing: 24) {
            Ficha(imagen: juego.a?.imagen, texto: juego.a?.nombre ?? "Animal 1", simbolo: "?", actual: juego.paso == 0)
            signo("+")
            Ficha(imagen: juego.b?.imagen, texto: juego.b?.nombre ?? "Animal 2", simbolo: "?", actual: juego.paso == 1)
            signo("=")
            Ficha(imagen: nil, texto: juego.paso == 2 ? (juego.nombre ?? "¿?") : "¿?", simbolo: "✨", actual: juego.paso == 2)
        }
    }

    private func signo(_ s: String) -> some View {
        Text(s).font(Tema.letra(50, .heavy)).foregroundStyle(Tema.yellow)
    }

    private var tarjetaNombre: some View {
        Ventana {
            Text("Tu alebrije se llama…").font(Tema.letra(36, .medium))
            Text("¡\(juego.nombre ?? "")!")
                .font(Tema.letra(130, .heavy))
                .foregroundStyle(Tema.purple)
                .shadow(color: Tema.yellow, radius: 0, x: 6, y: 6)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text("\(juego.a?.nombre ?? "") + \(juego.b?.nombre ?? "")").font(Tema.letra(36, .medium))
            Button("🎨 ¡Ahora los colores!") { juego.aColores() }
                .buttonStyle(BotonAlebrije(tamano: 40))
                .focused($foco, equals: .ventana)
                .padding(.top, 20)
        }
    }

    private var tarjetaAlebrije: some View {
        Ventana {
            Text("¡\(juego.nombre ?? "")!")
                .font(Tema.letra(70, .heavy))
                .foregroundStyle(Tema.purple)
                .shadow(color: Tema.yellow, radius: 0, x: 4, y: 4)
            Group {
                if let img = juego.alebrije {
                    Image(uiImage: img).resizable().scaledToFit()
                } else {
                    // por si se agrega un animal al manifiesto antes de generar sus mezclas
                    Text("\(juego.a?.emoji ?? "")\(juego.b?.emoji ?? "")").font(.system(size: 200))
                }
            }
            .frame(width: 600, height: 600)
            .background(RoundedRectangle(cornerRadius: 24).fill(Tema.paper))
            Button("🔄 Hacer otro alebrije") { juego.reiniciar() }
                .buttonStyle(BotonAlebrije(tamano: 40))
                .focused($foco, equals: .ventana)
                .padding(.top, 10)
        }
    }

    private var salir: (() -> Void)? {
        guard let ventana = juego.ventana else { return nil }
        return { [juego] in
            if ventana == .nombre { juego.aColores() } else { juego.reiniciar() }
        }
    }
}

private struct Ficha: View {
    let imagen: UIImage?
    let texto: String
    let simbolo: String
    let actual: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(Tema.paper)
                if let imagen {
                    Image(uiImage: imagen).resizable().scaledToFit().padding(18)
                        .transition(.scale(scale: 0).combined(with: .opacity))
                } else {
                    Text(simbolo).font(Tema.letra(40, .heavy)).foregroundStyle(Tema.paperInk)
                }
            }
            .frame(width: 100, height: 100)
            .overlay(Circle().stroke(Tema.ink, lineWidth: 5))
            .background(Circle().stroke(Tema.yellow, lineWidth: actual ? 18 : 0))
            Text(texto).font(Tema.letra(26)).foregroundStyle(.white).lineLimit(1)
        }
        .frame(width: 200)
        .opacity(actual || imagen != nil ? 1 : 0.55)
        .animation(.spring(duration: 0.5, bounce: 0.5), value: imagen == nil)
    }
}

private struct Ventana<Contenido: View>: View {
    @ViewBuilder var contenido: Contenido

    var body: some View {
        Papel(sombra: Tema.pink) {
            VStack(spacing: 14) {
                Picado()
                contenido
                    .foregroundStyle(Tema.paperInk)
            }
            .padding(.bottom, 44)
            .frame(width: 1000)
        }
    }
}
