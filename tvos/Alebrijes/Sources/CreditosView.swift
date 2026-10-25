import SwiftUI

// Resumen de creditos.html. En la tele no hay enlaces, así que se nombran autor y licencia.
struct CreditosView: View {
    var body: some View {
        Papel(sombra: Tema.blue) {
            VStack(alignment: .leading, spacing: 18) {
                seccion("Texto del cuento",
                        "Adaptado para niños de los artículos «Alebrije» de Wikipedia en español y en inglés, y «Pedro Linares» de Wikipedia en inglés (CC BY-SA 4.0). Por eso el texto del cuento se comparte bajo la misma licencia.")
                seccion("Fotografías",
                        "Alebrije tallándose en copal, Arrazola, Oaxaca (página 8): Nsaum75, CC BY-SA 4.0.\nAlebrijes monumentales en la CDMX (página 10): Secretaría de Cultura de la Ciudad de México, CC BY 2.0.")
                seccion("Ilustraciones y criaturas",
                        "Las ilustraciones del cuento, los animales y los alebrijes del juego fueron generados con inteligencia artificial. Las personas reales del cuento aparecen como personajes ilustrados, no como retratos.")
                seccion("Sobre los alebrijes",
                        "Los alebrijes de cartón nacieron en la Ciudad de México con Pedro Linares López y su familia, que sigue haciéndolos; los de madera de copal, en Arrazola, San Martín Tilcajete y otros pueblos de Oaxaca. Si compras un alebrije, busca que diga de qué comunidad viene.")
            }
            .padding(50)
            .frame(width: 1400, alignment: .leading)
        }
        // sin nada enfocable, el foco se queda en la pantalla y Menú regresa
        .focusable()
        .toolbar(.hidden, for: .navigationBar)
    }

    private func seccion(_ titulo: String, _ texto: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo).font(Tema.letra(38, .heavy))
            Text(texto).font(Tema.letra(26, .regular)).fixedSize(horizontal: false, vertical: true)
        }
    }
}
