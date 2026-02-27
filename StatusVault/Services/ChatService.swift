import Foundation

// Protocol for chat service - allows swapping between different AI providers
protocol ChatService {
    func sendMessage(_ message: String, conversationHistory: [ChatMessage], documentContext: String) async throws -> String
}

// Configuration for API keys
class ChatConfiguration {
    static let shared = ChatConfiguration()

    private init() {}

    // Store API key in UserDefaults (in production, use Keychain)
    var openAIAPIKey: String? {
        get {
            UserDefaults.standard.string(forKey: "openai_api_key")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "openai_api_key")
        }
    }

    var anthropicAPIKey: String? {
        get {
            UserDefaults.standard.string(forKey: "anthropic_api_key")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "anthropic_api_key")
        }
    }
}

enum ChatServiceError: Error, LocalizedError {
    case noAPIKey
    case invalidResponse
    case networkError(Error)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "API key not configured. Please add your API key in Settings."
        case .invalidResponse:
            return "Received invalid response from AI service."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}
