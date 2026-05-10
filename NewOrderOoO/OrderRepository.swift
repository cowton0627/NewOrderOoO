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
    case signInFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "尚未登入,請稍後再試"
        case .signInFailed(let underlying):
            return "登入失敗:\(underlying.localizedDescription)。\n請確認 Firebase Console > Authentication > Sign-in method 已啟用 Anonymous。"
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

    /// 拿 uid:已登入直接回,沒登入主動觸發 anonymous sign-in 並等它完成。
    /// 比 sync 版穩,即使 AppDelegate 的 anonymous sign-in 還沒完成也能擋住。
    private func currentUid() async throws -> String {
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
        let snapshot = try await db.collection(collectionName)
            .whereField("uid", isEqualTo: uid)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: OrderData.self) }
    }

    func deleteOrder(id: String) async throws {
        _ = try await currentUid()
        try await db.collection(collectionName).document(id).delete()
    }

    func updateOrder(id: String, orderName: String, size: DrinkSize, sugar: SugarLevel, ice: IceLevel, add: AddOn) async throws {
        _ = try await currentUid()
        try await db.collection(collectionName).document(id).updateData([
            "orderName": orderName,
            "drinkSize": size.rawValue,
            "sugar": sugar.rawValue,
            "cold": ice.rawValue,
            "add": add.rawValue,
        ])
    }

    /// Demo-only:把所有 uid 不是當前 user 的訂單接管過來。
    /// 場景:simulator 重新安裝後 anonymous uid 換了,舊資料卡在前一個 uid。
    /// 單用戶 demo 可接受;production / multi-user 必須關掉。
    func migrateLegacyOrdersIfNeeded() async throws {
        let uid = try await currentUid()

        let snapshot = try await db.collection(collectionName).getDocuments()
        for doc in snapshot.documents {
            let existingUid = doc.data()["uid"] as? String
            if existingUid != uid {
                try? await doc.reference.updateData(["uid": uid])
            }
        }
    }
}
