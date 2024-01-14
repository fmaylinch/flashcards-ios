//
//  Api.swift
//  Flashcards
//
//  Created by Ferran Maylinch carrasco on 14.01.2024.
//

import Foundation

func apiGet<T>(_ type: T.Type, path: String) async throws -> T where T : Decodable {
    
    let url = "\(Constants.baseUrl)/\(path)"
    var request = URLRequest(url: URL(string: url)!)
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    // TODO: get token from login
    request.addValue("Bearer: " + Constants.testToken, forHTTPHeaderField: "Authorization")
    
    do {
        print("Callling: \(url)")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode != 200 {
                throw ApiError.error("API response code: \(httpResponse.statusCode)")
            }
        }
        return try JSONDecoder().decode(type, from: data)
    }
}

enum ApiError: Error {
    case error(String)
}
