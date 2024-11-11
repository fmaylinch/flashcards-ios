import Foundation

class OpenAIService {
    
    static let shared = OpenAIService()
    
    func send(prompt: String, temperature: Double? = nil) async throws -> String {
        
        guard let url = URL(string: Constants.chatCompletionsUrl) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer " + Constants.openAiToken, forHTTPHeaderField: "Authorization")
        
        // According to OpenAI docs, when requesting "json_object" format,
        //   you must also instruct the model to produce JSON yourself via a message.
        //
        // TODO: Try gpt4 omni and structured outputs:
        // https://openai.com/index/introducing-structured-outputs-in-the-api/
        let userMessage = GPTMessage(role: "user", content: prompt)
        let payload = GPTChatPayload(
            model: "gpt-4", // gpt-4-turbo-preview (turbo works worse, it seems)
            messages: [userMessage],
            response_format: nil, // GPTResponseFormat(type: "json_object")
            temperature: temperature,
            top_p: nil)
        request.httpBody = try JSONEncoder().encode(payload)
        
        print("Making call to OpenAI with payload: \(payload)")
        let (data, _) = try await URLSession.shared.data(for: request)
        print("Response received from GTP: \(String(describing: String(data: data, encoding: .utf8)))")
        let chatResponse = try JSONDecoder().decode(GPTChatResponse.self, from: data)
        return chatResponse.choices[0].message.content
    }
    
    func send<T>(prompt: String, temperature: Double? = nil, answerType: T.Type) async throws -> T where T : Decodable {
        let json = try await send(prompt: prompt, temperature: temperature)
        return try JSONDecoder().decode(answerType, from: json.data(using: .utf8)!)
    }
}

struct GPTChatPayload: Codable {
    let model: String
    let messages: [GPTMessage]
    let response_format: GPTResponseFormat?
    // OpenAI doesn't recommend setting both temperature and top_p at the same tie
    let temperature: Double? // defaults to 1, it's value from 0 to 2 (2 is more random)
    let top_p: Double? // defaults to 1, 0.1 means top 10% tokens are considered
}

struct GPTMessage: Codable {
    let role: String
    let content: String
}

struct GPTChatResponse: Codable {
    let model: String
    let choices: [GPTChoice]
}

struct GPTChoice: Codable {
    let message: GPTMessage
}

struct GPTResponseFormat: Codable {
    let type: String
}
