import Foundation

enum OpenAIError: Error {
    case missingApiKey
    case badResponse
}

// MARK: - Request/Response payloads
private struct ChatCompletionRequest: Encodable {
    struct Message: Encodable {
        let role: String = "user"
        let content: String
    }
    let model: String
    let messages: [Message]
    let max_tokens: Int
    let temperature: Double
}

private struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable { let content: String }
        let message: Message
    }
    let choices: [Choice]
}

// MARK: - Client
final class OpenAISummaryClient {
    private let session: URLSession
    private let apiKey: String

    init(session: URLSession = .shared) throws {
        self.session = session
        guard let key = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
              !key.isEmpty else {
            throw OpenAIError.missingApiKey
        }
        self.apiKey = key
    }

    func summarize(paper: ArxivPaper, maxTokens: Int = 256) async throws -> String {
        // Prompt: we can feed the abstract (paper.summary)
        let prompt = """
        Summarize the following academic abstract in plain English within 4-5 sentences. Avoid jargon.

        \(paper.summary)
        """

        let body = ChatCompletionRequest(
            model: "gpt-3.5-turbo",
            messages: [.init(content: prompt)],
            max_tokens: maxTokens,
            temperature: 0.3
        )

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw OpenAIError.badResponse
        }
        let result = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        return result.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? "(no summary)"
    }
} 