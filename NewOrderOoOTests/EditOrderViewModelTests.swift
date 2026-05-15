//
//  EditOrderViewModelTests.swift
//  NewOrderOoOTests
//

import XCTest
@testable import NewOrderOoO

final class EditOrderViewModelTests: XCTestCase {

    private var repo: MockOrderRepository!
    private var sut: EditOrderViewModel!

    override func setUp() {
        super.setUp()
        repo = MockOrderRepository()
        let initial = OrderData(
            id: "order-1", orderName: "Alice", drinkName: "Latte",
            drinkSize: "Tall", sugar: "正常糖", cold: "正常冰", add: "珍珠",
            price: "TWD 90", quantity: 2, unitPrice: "TWD 45", uid: "test-uid"
        )
        sut = EditOrderViewModel(orderID: "order-1", initialOrder: initial, repository: repo)
    }

    override func tearDown() {
        sut = nil
        repo = nil
        super.tearDown()
    }

    // MARK: - 驗證

    func testSaveEmptyNameThrowsMissingName() async {
        do {
            try await sut.save(name: "  ", size: .tall, sugar: .full, ice: .normal, add: .pearl, quantity: 2)
            XCTFail("expected throw")
        } catch OrderError.missingName {
            // OK
        } catch {
            XCTFail("unexpected: \(error)")
        }
        XCTAssertEqual(repo.updateOrderCalls.count, 0, "驗證失敗不該打 repository")
    }

    func testSaveTrimsWhitespace() async throws {
        try await sut.save(name: "  Bob  ", size: .grande, sugar: .half, ice: .less, add: .aiyu, quantity: 2)
        XCTAssertEqual(repo.updateOrderCalls.count, 1)
        XCTAssertEqual(repo.updateOrderCalls[0].name, "Bob")
    }

    // MARK: - 寫入

    func testSaveHappyPathPassesAllArgsToRepository() async throws {
        try await sut.save(name: "Charles", size: .venti, sugar: .none, ice: .none, add: .grassJelly, quantity: 3)
        XCTAssertEqual(repo.updateOrderCalls.count, 1)
        let call = repo.updateOrderCalls[0]
        XCTAssertEqual(call.id, "order-1")
        XCTAssertEqual(call.name, "Charles")
        XCTAssertEqual(call.size, .venti)
        XCTAssertEqual(call.sugar, .none)
        XCTAssertEqual(call.ice, .none)
        XCTAssertEqual(call.add, .grassJelly)
        XCTAssertEqual(call.quantity, 3)
        XCTAssertEqual(call.unitPrice, Money.parse("TWD 45"), "unitPrice 應從 initialOrder.unitPrice 帶")
    }

    func testSaveClampsQuantityToAtLeastOne() async throws {
        try await sut.save(name: "Alice", size: .tall, sugar: .full, ice: .normal, add: .pearl, quantity: 0)
        XCTAssertEqual(repo.updateOrderCalls.first?.quantity, 1, "0 / 負數應被 clamp 成 1")
    }

    func testSavePropagatesRepositoryError() async {
        struct FakeError: Error {}
        repo.stubUpdateOrderError = FakeError()
        do {
            try await sut.save(name: "Alice", size: .tall, sugar: .full, ice: .normal, add: .pearl, quantity: 1)
            XCTFail("expected throw")
        } catch is FakeError {
            // OK
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }

    // MARK: - 初始狀態 + unitPrice fallback

    func testInitialOrderExposedForPrefill() {
        XCTAssertEqual(sut.orderID, "order-1")
        XCTAssertEqual(sut.initialOrder.orderName, "Alice")
        XCTAssertEqual(sut.initialOrder.drinkName, "Latte")
        XCTAssertEqual(sut.initialQuantity, 2)
    }

    func testInitialQuantityFallbacksToOneWhenMissing() {
        let legacy = OrderData(
            id: "old", orderName: "X", drinkName: "拿鐵咖啡",
            drinkSize: "Tall", sugar: "正常糖", cold: "正常冰", add: "珍珠",
            price: "TWD 45", quantity: nil, unitPrice: nil, uid: "test-uid"
        )
        let vm = EditOrderViewModel(orderID: "old", initialOrder: legacy, repository: repo)
        XCTAssertEqual(vm.initialQuantity, 1)
    }

    /// 舊文件沒 `unitPrice` 欄,從 `ProductCatalog` 反查 drinkName 取得單價
    func testUnitPriceFallbacksToCatalogWhenMissing() {
        let legacy = OrderData(
            id: "old", orderName: "X", drinkName: "拿鐵咖啡",
            drinkSize: "Tall", sugar: "正常糖", cold: "正常冰", add: "珍珠",
            price: "TWD 45", quantity: nil, unitPrice: nil, uid: "test-uid"
        )
        let vm = EditOrderViewModel(orderID: "old", initialOrder: legacy, repository: repo)
        XCTAssertEqual(vm.unitPrice, Money.parse("$45.00"))
    }

    /// 連 catalog 都查不到(產品被刪 / 改名),最後用 order.price 當 unitPrice
    func testUnitPriceFallbacksToOrderPriceWhenCatalogMissesToo() {
        let orphan = OrderData(
            id: "old", orderName: "X", drinkName: "已下架商品",
            drinkSize: "Tall", sugar: "正常糖", cold: "正常冰", add: "珍珠",
            price: "TWD 99", quantity: nil, unitPrice: nil, uid: "test-uid"
        )
        let vm = EditOrderViewModel(orderID: "old", initialOrder: orphan, repository: repo)
        XCTAssertEqual(vm.unitPrice, Money.parse("TWD 99"))
    }
}
