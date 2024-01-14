//
//  Api.swift
//  Flashcards
//
//  Created by Ferran Maylinch carrasco on 14.01.2024.
//

import Foundation


func apiPlay(file: String) {
    let url = "\(Constants.baseUrl)/audio/\(file)"
    AudioPlayerManager.shared.playSound(from: url)
}


func apiGet<T>(path: String, returnType: T.Type) async throws -> T where T : Decodable {
    
    let url = "\(Constants.baseUrl)/\(path)"
    var request = URLRequest(url: URL(string: url)!)
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    // TODO: get token from login
    request.addValue("Bearer: " + Constants.testToken, forHTTPHeaderField: "Authorization")
    
    print("Callling: \(url)")
    let (data, response) = try await URLSession.shared.data(for: request)
    if let httpResponse = response as? HTTPURLResponse {
        if httpResponse.statusCode != 200 {
            throw ApiError.error("API response code: \(httpResponse.statusCode)")
        }
    }
    return try JSONDecoder().decode(returnType, from: data)
}


func api<T>(method: String, data: Codable, path: String, returnType: T.Type, completion: @escaping (Result<T, Error>) -> Void) where T : Decodable {
    
    // TODO: this part is like apiGet
    let url = "\(Constants.baseUrl)/\(path)"
    var request = URLRequest(url: URL(string: url)!)
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    // TODO: get token from login
    request.addValue("Bearer: " + Constants.testToken, forHTTPHeaderField: "Authorization")
    
    request.httpMethod = method
    do {
        request.httpBody = try JSONEncoder().encode(data)
    } catch {
        completion(.failure(error))
    }
    
    print("Callling: \(url)")
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        do {
            if let error = error {
                completion(.failure(error))
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                completion(.failure(ApiError.error("API response code: \(httpResponse.statusCode)")))
            } else {
                if let data = data {
                    let result = try JSONDecoder().decode(returnType, from: data)
                    completion(.success(result))
                } else {
                    completion(.failure(ApiError.error("API response is 200 but it doesn't contain data")))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    task.resume()
}


enum ApiError: Error {
    case error(String)
}
