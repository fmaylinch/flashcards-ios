//
//  OpenAIService.swift
//  Flashcards
//
//  Created by Ferran Maylinch carrasco on 19.01.2024.
//

import Foundation

class OpenAIService {
    
    static let shared = OpenAIService()
    
    func send(message: String) async throws -> String {
        
        guard let url = URL(string: Constants.chatCompletionsUrl) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer " + Constants.openAiToken, forHTTPHeaderField: "Authorization")
        
        let userMessage = GPTMessage(role: "user", content: message)
        let payload = GPTChatPayload(model: "gpt-4", messages: [userMessage])
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let chatResponse = try JSONDecoder().decode(GPTChatResponse.self, from: data)
        return chatResponse.choices[0].message.content
    }
}

struct GPTChatPayload: Encodable {
    let model: String
    let messages: [GPTMessage]
}

struct GPTMessage: Encodable, Decodable {
    let role: String
    let content: String
    
    private enum CodingKeys: String, CodingKey {
        case role = "role"
        case content = "content"
    }
}

struct GPTChatResponse: Encodable, Decodable {
    let model: String
    let choices: [GPTChoice]
    
    private enum CodingKeys: String, CodingKey {
        case model = "model"
        case choices = "choices"
    }
}

struct GPTChoice: Encodable, Decodable {
    let message: GPTMessage
    
    private enum CodingKeys: String, CodingKey {
        case message = "message"
    }
}
