//
//  OrderListViewModelTests.swift
//  NewOrderOoOTests
//

import XCTest
@testable import NewOrderOoO

final class OrderListViewModelTests: XCTestCase {

    private var repo: MockOrderRepository!
    private var sut: OrderListViewModel!

    override func setUp() {
        super.setUp()
        repo = MockOrderRepository()
        sut = OrderListViewModel(repository: repo)
    }

    override func tearDown() {
        sut = nil
        repo = nil
        super.tearDown()
    }

    private func makeOrder(id: String, name: String) -> OrderData {
        OrderData(
            id: id, orderName: name, drinkName: "Latte",
            drinkSize: "Tall", sugar: "正常糖", cold: "正常冰", add: "珍珠",
            price: "TWD 45", uid: "test-uid"
        )
    }

    // MARK: - load

    func testLoadEmpty() async throws {
        repo.stubFetchOrders = []
        try await sut.load()
        XCTAssertEqual(sut.numberOfOrders, 0)
        XCTAssertTrue(repo.migrateCalled, "load 應該先觸發 migration")
    }

    func testLoadWithOrders() async throws {
        repo.stubFetchOrders = [makeOrder(id: "1", name: "Alice"), makeOrder(id: "2", name: "Bob")]
        try await sut.load()
        XCTAssertEqual(sut.numberOfOrders, 2)
        XCTAssertEqual(sut.order(at: 0).orderName, "Alice")
        XCTAssertEqual(sut.order(at: 1).orderName, "Bob")
    }

    func testLoadPropagatesError() async {
        struct FakeError: Error {}
        repo.stubFetchError = FakeError()
        do {
            try await sut.load()
            XCTFail("expected throw")
        } catch is FakeError {
            // OK
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }

    // MARK: - delete

    func testDeleteOptimistic() async throws {
        repo.stubFetchOrders = [makeOrder(id: "1", name: "A"), makeOrder(id: "2", name: "B")]
        try await sut.load()
        try await sut.delete(at: 0)
        XCTAssertEqual(sut.numberOfOrders, 1)
        XCTAssertEqual(sut.order(at: 0).orderName, "B")
        XCTAssertEqual(repo.deleteOrderCalls, ["1"])
    }

    // MARK: - avatar

    func testAvatarStable() {
        // 同個 row 永遠回同一個 asset name
        XCTAssertEqual(sut.avatarAssetName(for: 0), sut.avatarAssetName(for: 0))
        XCTAssertEqual(sut.avatarAssetName(for: 7), sut.avatarAssetName(for: 7))
    }

    func testAvatarRange() {
        // 8 個頭像循環
        for i in 0..<24 {
            let name = sut.avatarAssetName(for: i)
            XCTAssertTrue(name.hasPrefix("00"))
            let last = Int(name.suffix(1))
            XCTAssertNotNil(last)
            XCTAssertGreaterThanOrEqual(last!, 1)
            XCTAssertLessThanOrEqual(last!, 8)
        }
    }
}
