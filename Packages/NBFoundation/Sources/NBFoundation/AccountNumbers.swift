//
//  AccountNumbers.swift
//  NBFoundation
//
//  Swift port of nb-common com.northbridge.common.account.AccountNumbers.
//  DDA numbers are 12 digits: 3-digit branch, 8-digit serial, Luhn check digit.
//

import Foundation

public enum AccountNumbers {

    public static let length = 12

    public static func isValid(_ accountNumber: String) -> Bool {
        guard accountNumber.count == length,
              accountNumber.allSatisfy({ $0.isASCII && $0.isNumber }) else {
            return false
        }
        return luhnCheck(accountNumber)
    }

    /// "104000123455" -> "********3455". Anything shorter than 4 characters is fully masked.
    public static func mask(_ accountNumber: String) -> String {
        guard accountNumber.count > 4 else {
            return String(repeating: "*", count: accountNumber.count)
        }
        let lastFour = accountNumber.suffix(4)
        return String(repeating: "*", count: accountNumber.count - 4) + lastFour
    }

    /// "...3455" for compact list rows.
    public static func shortMask(_ accountNumber: String) -> String {
        "..." + accountNumber.suffix(4)
    }

    public static func branchCode(_ accountNumber: String) -> String? {
        guard isValid(accountNumber) else { return nil }
        return String(accountNumber.prefix(3))
    }

    static func luhnCheck(_ digits: String) -> Bool {
        var sum = 0
        for (index, character) in digits.reversed().enumerated() {
            guard var digit = character.wholeNumberValue else { return false }
            if index % 2 == 1 {
                digit *= 2
                if digit > 9 { digit -= 9 }
            }
            sum += digit
        }
        return sum % 10 == 0
    }
}
