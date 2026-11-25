//
//  BankDates.swift
//  NBFoundation
//
//  Swift port of nb-common com.northbridge.common.time.BankDates.
//  Business dates are yyyy-MM-dd; timestamps are ISO-8601 local time in America/New_York.
//

import Foundation

public enum BankDates {

    public static let bankTimeZone = TimeZone(identifier: "America/New_York")!

    public static let businessDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = bankTimeZone
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    public static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = bankTimeZone
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f
    }()

    public static let displayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.timeZone = bankTimeZone
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    public static func businessDate(from string: String) -> Date? {
        businessDateFormatter.date(from: string)
    }

    public static func businessDateString(_ date: Date) -> String {
        businessDateFormatter.string(from: date)
    }

    public static func timestamp(from string: String) -> Date? {
        if let date = timestampFormatter.date(from: string) {
            return date
        }
        // Some upstream feeds append fractional seconds; trim and retry.
        if let dot = string.firstIndex(of: ".") {
            return timestampFormatter.date(from: String(string[..<dot]))
        }
        return nil
    }

    public static func timestampString(_ date: Date) -> String {
        timestampFormatter.string(from: date)
    }

    public static func displayString(forBusinessDate string: String) -> String {
        guard let date = businessDate(from: string) else { return string }
        return displayDateFormatter.string(from: date)
    }
}
