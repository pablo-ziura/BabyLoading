import Foundation

enum BabySize: String, CaseIterable {
    case lentil
    case blueberry
    case raspberry
    case cherry
    case strawberry
    case lime
    case plum
    case peach
    case lemon
    case apple
    case avocado
    case pear
    case pomegranate
    case mango
    case banana
    case carrot
    case papaya
    case grapefruit
    case corn
    case eggplant
    case cucumber
    case bunchOfGrapes
    case coconut
    case broccoli
    case zucchini
    case pineapple
    case sweetPotato
    case dragonFruit
    case cantaloupe
    case napaCabbage
    case jicama
    case butternutSquash
    case leek
    case watermelon
    case pumpkin
    case unknown
    
    var description: String {
        switch self {
        case .lentil: return "una Lenteja"
        case .blueberry: return "un Arándano"
        case .raspberry: return "una Frambuesa"
        case .cherry: return "una Cereza"
        case .strawberry: return "una Fresa"
        case .lime: return "una Lima"
        case .plum: return "una Ciruela"
        case .peach: return "un Melocotón"
        case .lemon: return "un Limón"
        case .apple: return "una Manzana"
        case .avocado: return "un Aguacate"
        case .pear: return "una Pera"
        case .pomegranate: return "una Granada"
        case .mango: return "un Mango"
        case .banana: return "un Plátano"
        case .carrot: return "una Zanahoria"
        case .papaya: return "una Papaya"
        case .grapefruit: return "un Pomelo"
        case .corn: return "una Mazorca"
        case .eggplant: return "una Berenjena"
        case .cucumber: return "un Pepino"
        case .bunchOfGrapes: return "un Ramo de Uvas"
        case .coconut: return "un Coco"
        case .broccoli: return "un Brócoli"
        case .zucchini: return "un Calabacín"
        case .pineapple: return "una Piña"
        case .sweetPotato: return "un Boniato"
        case .dragonFruit: return "una Pitaya"
        case .cantaloupe: return "un Melón Cantalupo"
        case .napaCabbage: return "una Col China"
        case .jicama: return "una Jícama"
        case .butternutSquash: return "una Calabaza Cacahuete"
        case .leek: return "un Puerro Gigante"
        case .watermelon: return "una Sandía"
        case .pumpkin: return "una Calabaza"
        default: return "un Misterio"
        }
    }
    
    static func from(week: Int) -> BabySize {
        // Mapping weeks to sizes. Assuming standard pregnancy progression.
        // Week 6 is usually when size comparisons start (e.g. lentil).
        // This is a simplified mapping based on the list order provided by the user.
        // We'll map the 35 items to weeks 6 to 40 inclusive.
        
        switch week {
        case 0..<6: return .unknown
        case 6: return .lentil
        case 7: return .blueberry
        case 8: return .raspberry
        case 9: return .cherry
        case 10: return .strawberry
        case 11: return .lime
        case 12: return .plum
        case 13: return .peach
        case 14: return .lemon
        case 15: return .apple
        case 16: return .avocado
        case 17: return .pear
        case 18: return .pomegranate
        case 19: return .mango
        case 20: return .banana
        case 21: return .carrot
        case 22: return .papaya
        case 23: return .grapefruit
        case 24: return .corn
        case 25: return .eggplant
        case 26: return .cucumber
        case 27: return .bunchOfGrapes
        case 28: return .coconut
        case 29: return .broccoli
        case 30: return .zucchini
        case 31: return .pineapple
        case 32: return .sweetPotato
        case 33: return .dragonFruit
        case 34: return .cantaloupe
        case 35: return .napaCabbage
        case 36: return .jicama
        case 37: return .butternutSquash
        case 38: return .leek
        case 39: return .watermelon
        case 40...Int.max: return .pumpkin // 40 and beyond
        default: return .unknown
        }
    }
}
