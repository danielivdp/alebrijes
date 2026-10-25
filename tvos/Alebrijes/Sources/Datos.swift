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

    // Datos compartidos con el sitio web: una sola fuente para web y tele
    private struct Manifiesto: Decodable {
        let animales: [Animal]
        let paletas: [Paleta]
    }

    private struct Cuento: Decodable {
        let paginas: [Pagina]
    }

    private static func leer<T: Decodable>(_ ruta: String, como: T.Type) -> T? {
        guard let datos = try? Data(contentsOf: url(ruta)) else { return nil }
        return try? JSONDecoder().decode(T.self, from: datos)
    }

    private static let manifiesto = leer("manifest.json", como: Manifiesto.self)
    static let animales: [Animal] = manifiesto?.animales ?? []
    static let paletas: [Paleta] = manifiesto?.paletas ?? []
    static let paginas: [Pagina] = leer("cuento.json", como: Cuento.self)?.paginas ?? []
}

struct Animal: Decodable, Hashable, Sendable {
    let slug: String
    let nombre: String
    let emoji: String
    let inicio: String
    let fin: String

    var imagen: UIImage? { Recursos.imagen("animales/\(slug).png") }
}

struct Paleta: Decodable, Sendable {
    enum Colores: Sendable {
        case original
        case lista([UInt32])
        // "Sorpresa" no tiene colores: rota el tono de toda la imagen al azar
        case tono
    }

    let etiqueta: String
    let colores: Colores

    private enum CodingKeys: String, CodingKey { case etiqueta, colores }

    // En el JSON: null = original, "tono" = sorpresa, o una lista de "#rrggbb"
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        etiqueta = try c.decode(String.self, forKey: .etiqueta)
        if try c.decodeNil(forKey: .colores) {
            colores = .original
        } else if let lista = try? c.decode([String].self, forKey: .colores) {
            colores = .lista(lista.compactMap { UInt32($0.dropFirst(), radix: 16) })
        } else {
            colores = .tono
        }
    }
}

let paletas = Recursos.paletas

struct Pagina: Decodable, Sendable {
    struct Foto: Decodable, Sendable {
        let credito: String

        private enum CodingKeys: String, CodingKey { case credito = "texto" }
    }

    let titulo: String
    let texto: [String]
    let imagen: String
    var foto: Foto? = nil
}

// El texto vive en assets/cuento.json, compartido con el sitio web (js/cuento.js).
let paginas = Recursos.paginas
