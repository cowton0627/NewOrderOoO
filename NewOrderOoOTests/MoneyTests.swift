//
//  MoneyTests.swift
//  NewOrderOoOTests
//

import XCTest
@testable import NewOrderOoO

final class MoneyTests: XCTestCase {

    func testParseDollarSign() {
        let m = Money.parse("$45.00")
        XCTAssertEqual(m?.amount, Decimal(string: "45.00"))
    }

    func testParseTWDPrefix() {
        XCTAssertEqual(Money.parse("TWD 90")?.amount, Decimal(90))
    }

    func testParseWithComma() {
        XCTAssertEqual(Money.parse("$1,250")?.amount, Decimal(1250))
    }

    func testParseInvalid() {
        XCTAssertNil(Money.parse("not a number"))
    }

    func testParseEmpty() {
        XCTAssertNil(Money.parse(""))
    }

    func testMultiplyByInt() {
        let m = Money(amount: 45)
        XCTAssertEqual((m * 3).amount, 135)
    }

    func testMultiplyByZero() {
        XCTAssertEqual((Money(amount: 50) * 0).amount, 0)
    }

    /// Decimal 不該有 Double 浮點誤差。
    func testDecimalPrecisionNoFloatError() {
        let m = Money(amount: Decimal(string: "0.1")!)
        XCTAssertEqual((m * 3).amount, Decimal(string: "0.3"))
    }

    func testFormattedISO() {
        XCTAssertEqual(Money(amount: 90).formattedISO(), "TWD 90")
    }

    func testStorageString() {
        XCTAssertEqual(Money(amount: 45).storageString(), "$45.00")
    }
}
