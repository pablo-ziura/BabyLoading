import Foundation

enum BabySize: String, CaseIterable {
    case lentil
    case blueberry
    case raspberry
    case cherry
    case strawberry
    case fig            // CHANGED: Replaces lime (more accurate for 4cm)
    case plum
    case peach
    case lemon
    case apple
    case avocado
    case pear
    case bellPepper     // CHANGED: Common in Spain, fits 14cm size well
    case mango
    case sweetPotato    // REORDERED: Moved from late weeks to reflect 16cm size
    case carrot         // REORDERED: Marks the shift to total length measurement (~26cm)
    case banana         // REORDERED: Better fit here for length (~28cm)
    case eggplant       // REORDERED: Fits ~29cm
    case corn
    case cauliflower    // CHANGED: Starts the volume/weight gain phase (~34cm)
    case zucchini
    case cucumber
    case coconut        // REORDERED
    case butternutSquash
    case cabbage        // CHANGED: Replaces Napa Cabbage
    case bunchOfGrapes
    case pineapple      // REORDERED
    case cantaloupe
    case honeydew       // CHANGED: "Melón piel de sapo", extremely common in Spain
    case papaya         // REORDERED: Moved here to represent a large fruit (~46cm)
    case winterSquash   // CHANGED: "Calabaza de asar", round and heavy
    case bunchOfBananas // CHANGED: Replaces the illogical leek. Represents ~3kg weight.
    case smallWatermelon // CHANGED: Smoother transition to the final pumpkin
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
        case .fig: return "un higo"
        case .plum: return "una ciruela"
        case .peach: return "un melocotón"
        case .lemon: return "un limón"
        case .apple: return "una manzana"
        case .avocado: return "un aguacate"
        case .pear: return "una pera"
        case .bellPepper: return "un pimiento"
        case .mango: return "un mango"
        case .sweetPotato: return "un boniato"
        case .carrot: return "una zanahoria"
        case .banana: return "un plátano"
        case .eggplant: return "una berenjena"
        case .corn: return "una mazorca de maíz"
        case .cauliflower: return "una coliflor"
        case .zucchini: return "un calabacín"
        case .cucumber: return "un pepino"
        case .coconut: return "un coco"
        case .butternutSquash: return "una calabaza cacahuete"
        case .cabbage: return "un repollo"
        case .bunchOfGrapes: return "un racimo de uvas"
        case .pineapple: return "una piña"
        case .cantaloupe: return "un melón cantalupo"
        case .honeydew: return "un melón piel de sapo"
        case .papaya: return "una papaya"
        case .winterSquash: return "una calabaza de asar"
        case .bunchOfBananas: return "un racimo de plátanos"
        case .smallWatermelon: return "una sandía pequeña"
        case .watermelon: return "una sandía"
        case .pumpkin: return "una calabaza"
        case .unknown: return "un misterio"
        }
    }

    var imageName: String {
        "img_\(rawValue.lowercased())"
    }

    static func from(week: Int) -> BabySize {
        switch week {
        case 0 ..< 6: return .unknown
        case 6: return .lentil
        case 7: return .blueberry
        case 8: return .raspberry
        case 9: return .cherry
        case 10: return .strawberry
        case 11: return .fig
        case 12: return .plum
        case 13: return .peach
        case 14: return .lemon
        case 15: return .apple
        case 16: return .avocado
        case 17: return .pear
        case 18: return .bellPepper
        case 19: return .mango
        case 20: return .sweetPotato
        case 21: return .carrot
        case 22: return .banana
        case 23: return .eggplant
        case 24: return .corn
        case 25: return .cauliflower
        case 26: return .zucchini
        case 27: return .cucumber
        case 28: return .coconut
        case 29: return .butternutSquash
        case 30: return .cabbage
        case 31: return .bunchOfGrapes
        case 32: return .pineapple
        case 33: return .cantaloupe
        case 34: return .honeydew
        case 35: return .papaya
        case 36: return .winterSquash
        case 37: return .bunchOfBananas
        case 38: return .smallWatermelon
        case 39: return .watermelon
        case 40 ... Int.max: return .pumpkin
        default: return .unknown
        }
    }
}
