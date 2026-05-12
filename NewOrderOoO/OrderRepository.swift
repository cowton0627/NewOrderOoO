//
//  OrderRepository.swift
//  NewOrderOoO
//
//  把 Firestore 對 orderList collection 的 CRUD 集中在這。
//  ViewController / ViewModel 注入 protocol,不直接碰 Firestore。
//

import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

protocol OrderRepository {
    func placeOrder(_ input: OrderInput) async throws -> String
    func fetchOrders() async throws -> [OrderData]
    func deleteOrder(id: String) async throws
    func updateOrder(id: String, orderName: String, size: DrinkSize, sugar: SugarLevel, ice: IceLevel, add: AddOn) async throws
}

enum RepositoryError: LocalizedError {
    case notAuthenticated
    case firebaseNotConfigured
    case signInFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "尚未登入,請稍後再試"
        case .firebaseNotConfigured:
            return "尚未設定 Firebase。請將 GoogleService-Info.plist 放到 NewOrderOoO/ 目錄後再使用訂單功能。"
        case .signInFailed(let underlying):
            return "登入失敗:\(underlying.localizedDescription)。\n請確認 Firebase Console > Authentication > Sign-in method 已啟用 Anonymous。"
        }
    }
}

final class FirestoreOrderRepository: OrderRepository {
    private var db: Firestore?
    private let collectionName: String

    init(db: Firestore? = nil, collectionName: String = "orderList") {
        self.db = db
        self.collectionName = collectionName
    }

    private func firestore() throws -> Firestore {
        if let db = db { return db }
        guard FirebaseApp.app() != nil else { throw RepositoryError.firebaseNotConfigured }
        let db = Firestore.firestore()
        self.db = db
        return db
    }

    /// 拿 uid:已登入直接回,沒登入主動觸發 anonymous sign-in 並等它完成。
    /// 比 sync 版穩,即使 AppDelegate 的 anonymous sign-in 還沒完成也能擋住。
    private func currentUid() async throws -> String {
        guard FirebaseApp.app() != nil else { throw RepositoryError.firebaseNotConfigured }
        if let uid = Auth.auth().currentUser?.uid { return uid }
        do {
            let result = try await Auth.auth().signInAnonymously()
            return result.user.uid
        } catch {
            throw RepositoryError.signInFailed(underlying: error)
        }
    }

    func placeOrder(_ input: OrderInput) async throws -> String {
        let uid = try await currentUid()
        let db = try firestore()
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
        let uid = try await currentUid()
        let db = try firestore()
        let snapshot = try await db.collection(collectionName)
            .whereField("uid", isEqualTo: uid)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: OrderData.self) }
    }

    func deleteOrder(id: String) async throws {
        _ = try await currentUid()
        let db = try firestore()
        try await db.collection(collectionName).document(id).delete()
    }

    func updateOrder(id: String, orderName: String, size: DrinkSize, sugar: SugarLevel, ice: IceLevel, add: AddOn) async throws {
        _ = try await currentUid()
        let db = try firestore()
        try await db.collection(collectionName).document(id).updateData([
            "orderName": orderName,
            "drinkSize": size.rawValue,
            "sugar": sugar.rawValue,
            "cold": ice.rawValue,
            "add": add.rawValue,
        ])
    }

}
