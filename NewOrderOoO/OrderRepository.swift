//
//  OrderRepository.swift
//  NewOrderOoO
//
//  把 Firestore 對 orderList collection 的 CRUD 集中在這。
//  ViewController / ViewModel 注入 protocol,不直接碰 Firestore。
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

protocol OrderRepository {
    func placeOrder(_ input: OrderInput) async throws -> String
    func fetchOrders() async throws -> [OrderData]
    func deleteOrder(id: String) async throws
    func updateOrder(id: String, orderName: String, size: DrinkSize, sugar: SugarLevel, ice: IceLevel, add: AddOn) async throws
    /// 一次性把沒有 uid 欄位的舊訂單收編到當前 user。
    func migrateLegacyOrdersIfNeeded() async throws
}

enum RepositoryError: LocalizedError {
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "尚未登入,請稍後再試"
        }
    }
}

final class FirestoreOrderRepository: OrderRepository {
    private let db: Firestore
    private let collectionName: String

    init(db: Firestore = .firestore(), collectionName: String = "orderList") {
        self.db = db
        self.collectionName = collectionName
    }

    private func currentUid() throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else { throw RepositoryError.notAuthenticated }
        return uid
    }

    func placeOrder(_ input: OrderInput) async throws -> String {
        let uid = try currentUid()
        let data: [String: Any] = [
            "orderName": input.orderName,
            "drinkName": input.drinkName,
            "drinkSize": input.size.rawValue,
            "sugar": input.sugar.rawValue,
            "cold": input.ice.rawValue,
            "add": input.add.rawValue,
            "price": input.totalPrice.formattedISO(),
            "uid": uid,
        ]
        let ref = try await db.collection(collectionName).addDocument(data: data)
        return ref.documentID
    }

    func fetchOrders() async throws -> [OrderData] {
        let uid = try currentUid()
        let snapshot = try await db.collection(collectionName)
            .whereField("uid", isEqualTo: uid)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: OrderData.self) }
    }

    func deleteOrder(id: String) async throws {
        _ = try currentUid()
        try await db.collection(collectionName).document(id).delete()
    }

    func updateOrder(id: String, orderName: String, size: DrinkSize, sugar: SugarLevel, ice: IceLevel, add: AddOn) async throws {
        _ = try currentUid()
        try await db.collection(collectionName).document(id).updateData([
            "orderName": orderName,
            "drinkSize": size.rawValue,
            "sugar": sugar.rawValue,
            "cold": ice.rawValue,
            "add": add.rawValue,
        ])
    }

    private static let migrationDoneKey = "OrderRepository.migratedLegacyOrders.v1"

    func migrateLegacyOrdersIfNeeded() async throws {
        if UserDefaults.standard.bool(forKey: Self.migrationDoneKey) { return }
        let uid = try currentUid()

        // Firestore 不支援 query「沒有某個欄位」,所以全 fetch 後逐筆檢查。
        // 只有 demo 階段資料量小可以這樣做。
        let snapshot = try await db.collection(collectionName).getDocuments()
        for doc in snapshot.documents {
            let data = doc.data()
            let existingUid = data["uid"] as? String
            if existingUid == nil || existingUid?.isEmpty == true {
                try? await doc.reference.updateData(["uid": uid])
            }
        }
        UserDefaults.standard.set(true, forKey: Self.migrationDoneKey)
    }
}
