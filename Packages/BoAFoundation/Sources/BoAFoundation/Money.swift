//
//  Money.swift
//  BoAFoundation
//
//  Swift port of boa-common com.bofa.common.money.Money.
//  Amounts travel as two-place decimal strings ("125.40").
//

import Foundation

public struct Money: Equatable, Comparable, Codable, CustomStringConvertible {

    public let amount: Decimal
    public let currencyCode: String

    public static let zero = Money(amount: 0)

    public init(amount: Decimal, currencyCode: String = "USD") {
        self.amount = amount
        self.currencyCode = currencyCode
    }

    /// Parses an API amount string. Returns nil for anything that is not a plain decimal.
    public init?(string: String, currencyCode: String = "USD") {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let value = Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX")) else {
            return nil
        }
        self.init(amount: value, currencyCode: currencyCode)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let money = Money(string: raw) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid amount: \(raw)")
        }
        self = money
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(apiString)
    }

    /// "1234.50" — the wire format expected by core-banking and payments hub.
    public var apiString: String {
        var value = amount
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 2, .bankers)
        return Money.apiFormatter.string(from: rounded as NSDecimalNumber) ?? "0.00"
    }

    /// "$1,234.50" / "-$42.18" for display.
    public var formatted: String {
        let formatter = Money.displayFormatter
        formatter.currencyCode = currencyCode
        return formatter.string(from: amount as NSDecimalNumber) ?? apiString
    }

    public var isNegative: Bool { amount < 0 }
    public var isPositive: Bool { amount > 0 }

    public var negated: Money { Money(amount: -amount, currencyCode: currencyCode) }

    public var description: String { formatted }

    public static func + (lhs: Money, rhs: Money) -> Money {
        Money(amount: lhs.amount + rhs.amount, currencyCode: lhs.currencyCode)
    }

    public static func - (lhs: Money, rhs: Money) -> Money {
        Money(amount: lhs.amount - rhs.amount, currencyCode: lhs.currencyCode)
    }

    public static func < (lhs: Money, rhs: Money) -> Bool {
        lhs.amount < rhs.amount
    }

    private static let apiFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.numberStyle = .decimal
        f.usesGroupingSeparator = false
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    private static let displayFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US")
        f.numberStyle = .currency
        return f
    }()
}
