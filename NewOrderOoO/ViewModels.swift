//
//  ViewModels.swift
//  NewOrderOoO
//
//  業務邏輯從 ViewController 抽出。
//  VM 不知道 UIKit;只負責資料與計算,UI 由 VC 套到畫面。
//

import Foundation

// MARK: - 商品列表

final class MenuListViewModel {
    let products: [ProductData]

    init(products: [ProductData] = ProductCatalog.all) {
        self.products = products
    }

    var numberOfProducts: Int { products.count }

    func product(at index: Int) -> ProductData { products[index] }
}

// MARK: - 商品詳細(下單)

final class MenuDetailViewModel {
    let product: ProductData
    private let repository: OrderRepository

    init(product: ProductData, repository: OrderRepository = FirestoreOrderRepository()) {
        self.product = product
        self.repository = repository
    }

    /// quantity 杯總額顯示文字 (例如 "TWD 90")
    func totalPriceText(quantity: Int) -> String {
        guard let unit = Money.parse(product.price) else { return product.price }
        return (unit * quantity).formattedISO()
    }

    /// 驗證 + 送單。throws OrderError 給 VC 顯示 alert。
    func placeOrder(
        name: String,
        size: DrinkSize,
        sugar: SugarLevel,
        ice: IceLevel,
        add: AddOn,
        quantity: Int
    ) async throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { throw OrderError.missingName }
        guard let unit = Money.parse(product.price) else { throw OrderError.invalidPrice }

        let input = OrderInput(
            orderName: trimmed,
            drinkName: product.name,
            size: size,
            sugar: sugar,
            ice: ice,
            add: add,
            unitPrice: unit,
            quantity: quantity
        )
        return try await repository.placeOrder(input)
    }
}

// MARK: - 訂單清單

final class OrderListViewModel {
    private let repository: OrderRepository
    private(set) var orders: [OrderData] = []

    init(repository: OrderRepository = FirestoreOrderRepository()) {
        self.repository = repository
    }

    var numberOfOrders: Int { orders.count }

    func order(at index: Int) -> OrderData { orders[index] }

    func load() async throws {
        orders = try await repository.fetchOrders()
    }

    /// 樂觀刪除:先從 orders 移除供 UI 立刻反映,再呼叫 repository。失敗時 throw,呼叫端可決定是否 rollback。
    func delete(at index: Int) async throws {
        let removed = orders.remove(at: index)
        guard let id = removed.id else { return }
        try await repository.deleteOrder(id: id)
    }

    func avatarAssetName(for index: Int) -> String {
        let n = (index % 8) + 1
        return String(format: "00%d", n)
    }
}
