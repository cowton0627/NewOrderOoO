//
//  MockOrderRepository.swift
//  NewOrderOoOTests
//

import Foundation
@testable import NewOrderOoO

final class MockOrderRepository: OrderRepository {
    // 設定:測試前可塞 stub 值
    var stubFetchOrders: [OrderData] = []
    var stubFetchError: Error?
    var stubPlaceOrderID: String = "test-order-id"
    var stubPlaceOrderError: Error?
    var stubDeleteOrderError: Error?
    var stubUpdateOrderError: Error?

    // 觀察:測試後可看呼叫紀錄
    private(set) var placeOrderCalls: [OrderInput] = []
    private(set) var deleteOrderCalls: [String] = []
    private(set) var updateOrderCalls: [(id: String, name: String, size: DrinkSize, sugar: SugarLevel, ice: IceLevel, add: AddOn)] = []

    func placeOrder(_ input: OrderInput) async throws -> String {
        placeOrderCalls.append(input)
        if let error = stubPlaceOrderError { throw error }
        return stubPlaceOrderID
    }

    func fetchOrders() async throws -> [OrderData] {
        if let error = stubFetchError { throw error }
        return stubFetchOrders
    }

    func deleteOrder(id: String) async throws {
        deleteOrderCalls.append(id)
        if let error = stubDeleteOrderError { throw error }
    }

    func updateOrder(id: String, orderName: String, size: DrinkSize, sugar: SugarLevel, ice: IceLevel, add: AddOn) async throws {
        updateOrderCalls.append((id, orderName, size, sugar, ice, add))
        if let error = stubUpdateOrderError { throw error }
    }
}
