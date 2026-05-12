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
            price: "TWD 45", uid: "test-uid"
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
            try await sut.save(name: "  ", size: .tall, sugar: .full, ice: .normal, add: .pearl)
            XCTFail("expected throw")
        } catch OrderError.missingName {
            // OK
        } catch {
            XCTFail("unexpected: \(error)")
        }
        XCTAssertEqual(repo.updateOrderCalls.count, 0, "驗證失敗不該打 repository")
    }

    func testSaveTrimsWhitespace() async throws {
        try await sut.save(name: "  Bob  ", size: .grande, sugar: .half, ice: .less, add: .aiyu)
        XCTAssertEqual(repo.updateOrderCalls.count, 1)
        XCTAssertEqual(repo.updateOrderCalls[0].name, "Bob")
    }

    // MARK: - 寫入

    func testSaveHappyPathPassesAllArgsToRepository() async throws {
        try await sut.save(name: "Charles", size: .venti, sugar: .none, ice: .none, add: .grassJelly)
        XCTAssertEqual(repo.updateOrderCalls.count, 1)
        let call = repo.updateOrderCalls[0]
        XCTAssertEqual(call.id, "order-1")
        XCTAssertEqual(call.name, "Charles")
        XCTAssertEqual(call.size, .venti)
        XCTAssertEqual(call.sugar, .none)
        XCTAssertEqual(call.ice, .none)
        XCTAssertEqual(call.add, .grassJelly)
    }

    func testSavePropagatesRepositoryError() async {
        struct FakeError: Error {}
        repo.stubUpdateOrderError = FakeError()
        do {
            try await sut.save(name: "Alice", size: .tall, sugar: .full, ice: .normal, add: .pearl)
            XCTFail("expected throw")
        } catch is FakeError {
            // OK
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }

    // MARK: - 初始狀態

    func testInitialOrderExposedForPrefill() {
        XCTAssertEqual(sut.orderID, "order-1")
        XCTAssertEqual(sut.initialOrder.orderName, "Alice")
        XCTAssertEqual(sut.initialOrder.drinkName, "Latte")
    }
}
