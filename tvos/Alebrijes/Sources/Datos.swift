import SwiftUI
import UIKit

/// Archivos de ../assets, empaquetados como carpeta "assets" dentro de la app.
enum Recursos {
    static func url(_ ruta: String) -> URL {
        Bundle.main.resourceURL!.appending(path: "assets/\(ruta)")
    }

    static func imagen(_ ruta: String) -> UIImage? {
        UIImage(contentsOfFile: url(ruta).path(percentEncoded: false))
    }

    static let animales: [Animal] = {
        struct Manifiesto: Decodable { let animales: [Animal] }
        guard let datos = try? Data(contentsOf: url("manifest.json")),
              let m = try? JSONDecoder().decode(Manifiesto.self, from: datos) else { return [] }
        return m.animales
    }()
}

struct Animal: Decodable, Hashable, Sendable {
    let slug: String
    let nombre: String
    let emoji: String
    let inicio: String
    let fin: String

    var imagen: UIImage? { Recursos.imagen("animales/\(slug).png") }
}

struct Paleta: Sendable {
    enum Colores: Sendable {
        case original
        case lista([UInt32])
        // "Sorpresa" no tiene colores: rota el tono de toda la imagen al azar
        case tono
    }

    let etiqueta: String
    let colores: Colores
}

// Mismas paletas que js/crear.js
let paletas: [Paleta] = [
    Paleta(etiqueta: "Original", colores: .original),
    Paleta(etiqueta: "Oaxaca", colores: .lista([0xe6332a, 0xffb000, 0x00a6a6, 0x7b2ff7, 0xff5fa2, 0x2bb24c])),
    Paleta(etiqueta: "Noche", colores: .lista([0x3b2cc2, 0xff2e9a, 0xffd000, 0x00c2ff, 0x8a1cff, 0xff7a00])),
    Paleta(etiqueta: "Selva", colores: .lista([0x1f9e45, 0xffd000, 0xff6a00, 0x00b3a4, 0xc1e000, 0xe6332a])),
    Paleta(etiqueta: "Mar", colores: .lista([0x0077d9, 0x00d4c8, 0xffffff, 0x7ad3ff, 0xffcf3a, 0xff7aa8])),
    Paleta(etiqueta: "Sorpresa", colores: .tono),
]

struct Pagina: Sendable {
    struct Foto: Sendable {
        let credito: String
    }

    let titulo: String
    let texto: String
    let imagen: String
    var foto: Foto? = nil
}

// Copia del texto de js/cuento.js, adaptado de "Alebrije" en es.wikipedia.org y en.wikipedia.org (CC BY-SA 4.0).
let paginas: [Pagina] = [
    Pagina(
        titulo: "Don Pedro, el cartonero",
        texto: "Hace mucho tiempo, en la Ciudad de México, vivía Don Pedro Linares. Era cartonero: con papel y engrudo hacía piñatas y máscaras que vendía en el mercado de La Merced.",
        imagen: "cuento/pagina-01.png"
    ),
    Pagina(
        titulo: "Una fiebre muy fuerte",
        texto: "En 1936, cuando tenía 30 años, Pedro se enfermó con una fiebre muy alta. Se quedó profundamente dormido y sus hermanas lo cuidaban con remedios caseros.",
        imagen: "cuento/pagina-02.png"
    ),
    Pagina(
        titulo: "El bosque del sueño",
        texto: "Mientras dormía, Pedro soñó con un bosque muy tranquilo, con árboles, rocas, nubes y cielo. Ahí no le dolía nada y se sentía feliz.",
        imagen: "cuento/pagina-03.png"
    ),
    Pagina(
        titulo: "¡Los animales cambian!",
        texto: "De pronto, los animales del bosque se transformaron en criaturas rarísimas: un burro con alas, un gallo con cuernos de toro y un león con cabeza de perro.",
        imagen: "cuento/pagina-04.png"
    ),
    Pagina(
        titulo: "«¡Alebrijes! ¡Alebrijes!»",
        texto: "Todas las criaturas gritaban la misma palabra: «¡Alebrijes!». Un señor que caminaba por un sendero de piedras le dijo que todavía no debía estar ahí y le mostró una ventanita para salir.",
        imagen: "cuento/pagina-05.png"
    ),
    Pagina(
        titulo: "De papel y colores",
        texto: "Pedro despertó sano. Para que todos conocieran a las criaturas de su sueño, las hizo de papel y cartón, y las pintó de colores brillantes, tal como las había visto.",
        imagen: "cuento/pagina-06.png"
    ),
    Pagina(
        titulo: "Diego y Frida",
        texto: "Los pintores Diego Rivera y Frida Kahlo conocieron su trabajo y le encargaron más alebrijes. Algunos de los que hizo para Diego Rivera hoy están en el Museo Anahuacalli.",
        imagen: "cuento/pagina-07.png"
    ),
    Pagina(
        titulo: "Alebrijes de madera",
        texto: "Los alebrijes llegaron a Oaxaca. Ahí, Manuel Jiménez y otros artesanos de Arrazola y San Martín Tilcajete empezaron a tallarlos en madera de copal.",
        imagen: "fotos/tallado-arrazola.jpg",
        foto: Pagina.Foto(credito: "Foto: Nsaum75, CC BY-SA 4.0")
    ),
    Pagina(
        titulo: "Un premio y una familia",
        texto: "En 1990, Pedro recibió el Premio Nacional de Ciencias y Artes por su creación. Murió en 1992, pero su hijo y sus nietos siguen haciendo alebrijes hasta hoy.",
        imagen: "cuento/pagina-09.png"
    ),
    Pagina(
        titulo: "La Noche de los Alebrijes",
        texto: "Desde 2007, en la Ciudad de México se hace un desfile de alebrijes gigantes. No hay dos alebrijes iguales… ¿y si inventas el tuyo?",
        imagen: "fotos/alebrijes-monumentales.jpg",
        foto: Pagina.Foto(credito: "Foto: Secretaría de Cultura de la Ciudad de México, CC BY 2.0")
    ),
]
