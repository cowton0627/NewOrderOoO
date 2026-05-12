//
//  OrderData.swift
//  NewOrderOoO
//

import Foundation
import FirebaseFirestore

struct OrderData: Codable, Identifiable {
    @DocumentID var id: String?
    var orderName: String
    var drinkName: String
    var drinkSize: String
    var sugar: String
    var cold: String
    var add: String
    var price: String
    var uid: String?  // 文件擁有者,給 Firestore Security Rules 用
}
