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
        case .lentil: return "una lenteja"
        case .blueberry: return "un arándano"
        case .raspberry: return "una frambuesa"
        case .cherry: return "una cereza"
        case .strawberry: return "una fresa"
        case .lime: return "una lima"
        case .plum: return "una ciruela"
        case .peach: return "un melocotón"
        case .lemon: return "un limón"
        case .apple: return "una anzana"
        case .avocado: return "un aguacate"
        case .pear: return "una pera"
        case .pomegranate: return "una ranada"
        case .mango: return "un mango"
        case .banana: return "un plátano"
        case .carrot: return "una zanahoria"
        case .papaya: return "una papaya"
        case .grapefruit: return "un omelo"
        case .corn: return "una mazorca"
        case .eggplant: return "una berenjena"
        case .cucumber: return "un pepino"
        case .bunchOfGrapes: return "un racimo de uvas"
        case .coconut: return "un coco"
        case .broccoli: return "un brócoli"
        case .zucchini: return "un calabacín"
        case .pineapple: return "una piña"
        case .sweetPotato: return "un boniato"
        case .dragonFruit: return "una pitaya"
        case .cantaloupe: return "un melón pequeño"
        case .napaCabbage: return "una col"
        case .jicama: return "una jícama"
        case .butternutSquash: return "una calabaza cacahuete"
        case .leek: return "un puerro enorme"
        case .watermelon: return "una aandía"
        case .pumpkin: return "una calabaza"
        default: return "un misterio"
        }
    }

    static func from(week: Int) -> BabySize {
        switch week {
        case 0 ..< 6: return .unknown
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
        case 40 ... Int.max: return .pumpkin // 40 and beyond
        default: return .unknown
        }
    }
}
