import Foundation

enum BabySize: String, CaseIterable, Codable {
    case lentil
    case blueberry
    case raspberry
    case cherry
    case strawberry
    case fig
    case plum
    case peach
    case lemon
    case apple
    case avocado
    case pear
    case bellPepper
    case mango
    case sweetPotato
    case carrot
    case banana
    case eggplant
    case corn
    case cauliflower
    case zucchini
    case cucumber
    case coconut
    case butternutSquash
    case cabbage
    case bunchOfGrapes
    case pineapple
    case cantaloupe
    case honeydew
    case papaya
    case winterSquash
    case bunchOfBananas
    case smallWatermelon
    case watermelon
    case pumpkin
    case unknown

    var imageName: String {
        "img_\(rawValue.lowercased())"
    }
}
