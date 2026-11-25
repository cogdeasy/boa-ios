import Foundation

enum APIError: Error, Equatable {
    case unauthorized
    case forbidden
    case notFound(code: String?)
    case business(code: String, message: String)
    case server(status: Int)
    case transport(message: String)
    case decoding(message: String)
    case invalidRequest

    var userMessage: String {
        switch self {
        case .unauthorized:
            return "Your Online ID or passcode is incorrect."
        case .forbidden:
            return "You don't have access to this account."
        case .notFound:
            return "We couldn't find that account."
        case .business(let code, let message):
            switch code {
            case "NSF": return "Insufficient available funds for this transfer."
            case "LIMIT_EXCEEDED": return "This amount exceeds your daily transfer limit."
            case "DUPLICATE": return "This transfer was already submitted."
            default: return message
            }
        case .server:
            return "Something went wrong on our side. Please try again later."
        case .transport:
            return "We can't reach Northbridge right now. Check your connection and try again."
        case .decoding:
            return "We received an unexpected response. Please try again."
        case .invalidRequest:
            return "Please check the details and try again."
        }
    }
}
