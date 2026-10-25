import SwiftUI

enum Pantalla: Hashable {
    case cuento, crear, creditos
}

@main
struct AlebrijesApp: App {
    // Para capturas en el simulador sin control remoto: `simctl launch … -pantalla crear`
    @State private var ruta: [Pantalla] = {
        switch UserDefaults.standard.string(forKey: "pantalla") {
        case "cuento": [.cuento]
        case "crear": [.crear]
        case "creditos": [.creditos]
        default: []
        }
    }()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $ruta) {
                Inicio(ruta: $ruta)
                    .navigationDestination(for: Pantalla.self) { pantalla in
                        switch pantalla {
                        case .cuento: CuentoView(alTerminar: { ruta = [.crear] })
                        case .crear: CrearView()
                        case .creditos: CreditosView()
                        }
                    }
            }
            .background(Fondo())
        }
    }
}
