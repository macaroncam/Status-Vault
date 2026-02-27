import Foundation

class OpenAIChatService: ChatService {
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4o-mini" // Fast and cost-effective

    func sendMessage(_ message: String, conversationHistory: [ChatMessage], documentContext: String) async throws -> String {
        guard let apiKey = ChatConfiguration.shared.openAIAPIKey, !apiKey.isEmpty else {
            throw ChatServiceError.noAPIKey
        }

        // Build messages array
        var messages: [[String: String]] = []

        // System prompt with document context
        let systemPrompt = DocumentContextBuilder.shared.buildSystemPrompt()
        messages.append([
            "role": "system",
            "content": systemPrompt + "\n\nCurrent User Context:\n" + documentContext
        ])

        // Add conversation history (last 10 messages for context window management)
        let recentHistory = conversationHistory.suffix(10)
        for historyMessage in recentHistory {
            messages.append([
                "role": historyMessage.role.rawValue,
                "content": historyMessage.content
            ])
        }

        // Add current user message
        messages.append([
            "role": "user",
            "content": message
        ])

        // Create request
        guard let url = URL(string: baseURL) else {
            throw ChatServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 1000
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            // Try to parse error message
            if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorDict["error"] as? [String: Any],
               let errorMessage = error["message"] as? String {
                throw ChatServiceError.apiError(errorMessage)
            }
            throw ChatServiceError.apiError("HTTP \(httpResponse.statusCode)")
        }

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw ChatServiceError.invalidResponse
        }

        return content
    }
}

// Alternative: Anthropic Claude service implementation
class AnthropicChatService: ChatService {
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-3-5-sonnet-20241022"

    func sendMessage(_ message: String, conversationHistory: [ChatMessage], documentContext: String) async throws -> String {
        guard let apiKey = ChatConfiguration.shared.anthropicAPIKey, !apiKey.isEmpty else {
            throw ChatServiceError.noAPIKey
        }

        // Build messages array (Anthropic format)
        var messages: [[String: Any]] = []

        // Add conversation history
        let recentHistory = conversationHistory.suffix(10)
        for historyMessage in recentHistory {
            messages.append([
                "role": historyMessage.role.rawValue,
                "content": historyMessage.content
            ])
        }

        // Add current user message
        messages.append([
            "role": "user",
            "content": message
        ])

        // Create request
        guard let url = URL(string: baseURL) else {
            throw ChatServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let systemPrompt = DocumentContextBuilder.shared.buildSystemPrompt() + "\n\nCurrent User Context:\n" + documentContext

        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": systemPrompt,
            "messages": messages
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorDict["error"] as? [String: Any],
               let errorMessage = error["message"] as? String {
                throw ChatServiceError.apiError(errorMessage)
            }
            throw ChatServiceError.apiError("HTTP \(httpResponse.statusCode)")
        }

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw ChatServiceError.invalidResponse
        }

        return text
    }
}
