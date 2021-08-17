//
//  OrderData.swift
//  NewOrderOoO
//
//  Created by 鄭淳澧 on 2021/8/16.
//

import Foundation
import FirebaseFirestoreSwift

struct OrderData: Codable, Identifiable {
    @DocumentID var id: String?
    var orderName: String
    var drinkName: String
    var drinkSize: String
    var sugar: String
    var cold: String
    var add: String
    var price: String
}


//struct OrderData: {
//    var documentId: String
//    var orderName: String
//    var drinkName: String
//    var drinkSize: String
//    var sugar: String
//    var cold: String
//    var add: String
//    var price: String
//}
