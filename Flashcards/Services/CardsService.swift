//
//  Api.swift
//  Flashcards
//
//  Created by Ferran Maylinch carrasco on 14.01.2024.
//

import Foundation

class CardsService {
    
    static let shared = CardsService()
    
    func playAudio(file: String) {
        let url = "\(Constants.baseUrl)/audio/\(file)"
        AudioPlayerManager.shared.playSound(from: url)
    }
    
    func generateAndPlayAudio(text: String) async throws {
        let cardToListen = simpleCard(front: text)
        let testCard = try await CardsService.shared.call(
            method: "POST",
            path: "cards/tts",
            data: cardToListen,
            returnType: Card.self)
        let file = testCard.files![0]
        CardsService.shared.playAudio(file: file)
    }
        
    func call<T>(method: String,
                 path: String,
                 data: Codable? = nil,
                 returnType: T.Type) async throws -> T where T : Decodable {
        
        let url = "\(Constants.baseUrl)/\(path)"
        var request = URLRequest(url: URL(string: url)!)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // TODO: get token from login
        request.addValue("Bearer: " + Constants.testToken, forHTTPHeaderField: "Authorization")
        request.httpMethod = method
        if let data = data {
            request.httpBody = try JSONEncoder().encode(data)
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(returnType, from: data)
    }
}

