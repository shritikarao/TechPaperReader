import Foundation

enum XAIError: Error {
    case missingApiKey
    case badResponse
}

// MARK: - Request/Response Payloads
private struct XAIChatCompletionRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }
    let model: String
    let messages: [Message]
    let max_tokens: Int
    let temperature: Double
}

private struct XAIChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

// MARK: - Client
final class XAIClient {
    private let session: URLSession
    private let apiKey: String

    init(session: URLSession = .shared) throws {
        self.session = session
        // Prefer environment variable so secrets aren't committed.
        if let envKey = ProcessInfo.processInfo.environment["XAI_API_KEY"], !envKey.isEmpty {
            self.apiKey = envKey
        } else if let plistKey = Bundle.main.object(forInfoDictionaryKey: "XAI_API_KEY") as? String,
                  !plistKey.isEmpty,
                  !plistKey.contains("YOUR_XAI_API_KEY_HERE") {
            self.apiKey = plistKey
        } else {
            throw XAIError.missingApiKey
        }
    }

    func summarize(text: String, model: String = "grok-3", maxTokens: Int = 512) async throws -> String {
        let systemPrompt = "Summarize the following text in plain English within 8-10 sentences. Focus on the key findings and conclusions."
        
        let messages = [
            XAIChatCompletionRequest.Message(role: "system", content: systemPrompt),
            XAIChatCompletionRequest.Message(role: "user", content: text)
        ]

        let body = XAIChatCompletionRequest(
            model: model,
            messages: messages,
            max_tokens: maxTokens,
            temperature: 0.3
        )

        var request = URLRequest(url: URL(string: "https://api.x.ai/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            // You can add more detailed error handling here based on the response body
            if let http = response as? HTTPURLResponse {
                let statusCode = http.statusCode
                let responseBody = String(data: data, encoding: .utf8) ?? "Could not decode body"
                print("[XAIClient] Error: Received status code \(statusCode)")
                print("[XAIClient] Error: Response body: \(responseBody)")
            }
            throw XAIError.badResponse
        }
        let result = try JSONDecoder().decode(XAIChatCompletionResponse.self, from: data)
        return result.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? "(No summary available)"
    }
    
    func summarize(paper: ArxivPaper) async throws -> String {
        return try await summarize(text: paper.summary)
    }
} 

