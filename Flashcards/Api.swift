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


func api<T>(method: String,
            data: Codable? = nil,
            path: String,
            returnType: T.Type,
            completion: @escaping (Result<T, Error>) -> Void) where T : Decodable {
    
    let url = "\(Constants.baseUrl)/\(path)"
    var request = URLRequest(url: URL(string: url)!)
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    // TODO: get token from login
    request.addValue("Bearer: " + Constants.testToken, forHTTPHeaderField: "Authorization")
    request.httpMethod = method

    if let data = data {
        do {
            request.httpBody = try JSONEncoder().encode(data)
        } catch {
            completion(.failure(error))
        }
    }
    
    print("API call \(method) to \(url)")
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        do {
            if let error = error {
                print("API response -> there was an error: \(error)")
                completion(.failure(error))
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("API response -> status code is not 200 but: \(httpResponse.statusCode)")
                completion(.failure(ApiError.error("API response code: \(httpResponse.statusCode)")))
            } else {
                if let data = data {
                    let result = try JSONDecoder().decode(returnType, from: data)
                    DispatchQueue.main.async {
                        print("API response -> OK")
                        completion(.success(result))
                    }
                } else {
                    print("API response -> status code is 200 but there's no data")
                    completion(.failure(ApiError.error("API response is 200 but it doesn't contain data")))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    task.resume()
}
