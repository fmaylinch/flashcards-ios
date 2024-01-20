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
    
    func call<T>(method: String,
                 data: Codable? = nil,
                 path: String,
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

