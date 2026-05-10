//
//  MenuDetailViewModelTests.swift
//  NewOrderOoOTests
//

import XCTest
@testable import NewOrderOoO

final class MenuDetailViewModelTests: XCTestCase {

    private var repo: MockOrderRepository!
    private var sut: MenuDetailViewModel!

    override func setUp() {
        super.setUp()
        repo = MockOrderRepository()
        let product = ProductData(
            imgName: "x", name: "Test Drink", price: "$50.00",
            content: "副標", description: "描述"
        )
        sut = MenuDetailViewModel(product: product, repository: repo)
    }

    override func tearDown() {
        sut = nil
        repo = nil
        super.tearDown()
    }

    // MARK: - 價格計算

    func testTotalPriceTextSingle() {
        XCTAssertEqual(sut.totalPriceText(quantity: 1), "TWD 50")
    }

    func testTotalPriceTextMultiple() {
        XCTAssertEqual(sut.totalPriceText(quantity: 3), "TWD 150")
    }

    func testTotalPriceFallbackForUnparsablePrice() {
        let invalid = ProductData(imgName: "x", name: "X", price: "abc", content: "", description: "")
        let vm = MenuDetailViewModel(product: invalid, repository: repo)
        // parse 失敗時 fallback 顯示原 price 字串
        XCTAssertEqual(vm.totalPriceText(quantity: 2), "abc")
    }

    // MARK: - 下單

    func testPlaceOrderEmptyNameThrowsMissingName() async {
        do {
            _ = try await sut.placeOrder(name: "  ", size: .tall, sugar: .full, ice: .normal, add: .pearl, quantity: 1)
            XCTFail("expected throw")
        } catch OrderError.missingName {
            // OK
        } catch {
            XCTFail("unexpected: \(error)")
        }
        XCTAssertEqual(repo.placeOrderCalls.count, 0, "驗證失敗時不該打 repository")
    }

    func testPlaceOrderHappyPath() async throws {
        let id = try await sut.placeOrder(name: "Alice", size: .grande, sugar: .half, ice: .less, add: .aiyu, quantity: 2)
        XCTAssertEqual(id, "test-order-id")
        XCTAssertEqual(repo.placeOrderCalls.count, 1)

        let input = repo.placeOrderCalls[0]
        XCTAssertEqual(input.orderName, "Alice")
        XCTAssertEqual(input.drinkName, "Test Drink")
        XCTAssertEqual(input.size, .grande)
        XCTAssertEqual(input.sugar, .half)
        XCTAssertEqual(input.ice, .less)
        XCTAssertEqual(input.add, .aiyu)
        XCTAssertEqual(input.quantity, 2)
        XCTAssertEqual(input.unitPrice.amount, 50)
        XCTAssertEqual(input.totalPrice.amount, 100)
    }

    func testPlaceOrderTrimsWhitespace() async throws {
        _ = try await sut.placeOrder(name: "  Alice  ", size: .tall, sugar: .full, ice: .normal, add: .pearl, quantity: 1)
        XCTAssertEqual(repo.placeOrderCalls[0].orderName, "Alice")
    }

    func testPlaceOrderInvalidPriceThrows() async {
        let invalid = ProductData(imgName: "x", name: "X", price: "no price", content: "", description: "")
        let vm = MenuDetailViewModel(product: invalid, repository: repo)
        do {
            _ = try await vm.placeOrder(name: "Alice", size: .tall, sugar: .full, ice: .normal, add: .pearl, quantity: 1)
            XCTFail("expected throw")
        } catch OrderError.invalidPrice {
            // OK
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }

    func testPlaceOrderPropagatesRepositoryError() async {
        struct FakeError: Error {}
        repo.stubPlaceOrderError = FakeError()
        do {
            _ = try await sut.placeOrder(name: "Alice", size: .tall, sugar: .full, ice: .normal, add: .pearl, quantity: 1)
            XCTFail("expected throw")
        } catch is FakeError {
            // OK
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }
}
