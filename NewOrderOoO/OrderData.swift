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
    var quantity: Int? = nil      // 杯數;Firestore schema 後加的欄位,舊文件可能沒有,所以 optional
    var unitPrice: String? = nil  // 單杯價格(例如 "TWD 45"),用於編輯時重算總額;同上,舊文件可能沒有
    var uid: String? = nil  // 文件擁有者,給 Firestore Security Rules 用
}
