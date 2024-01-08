//
//  Models.swift
//  Flashcards
//
//  Created by Ferran Maylinch carrasco on 08.01.2024.
//

import Foundation

@MainActor
class CardsFromApi: ObservableObject {
    
    @Published var cards: [Card] = []
    
    func fetch() async throws {
        let url = "http://158.160.43.18:3001/cards/list"
        var request = URLRequest(url: URL(string: url)!)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let token = "TOKEN"
        request.addValue("Bearer: " + token, forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: request)
        let cardsResponse = try JSONDecoder().decode(CardsResponse.self, from: data)
        cards = cardsResponse.cards.shuffled()
    }
}

struct CardsResponse: Decodable {
    let cards: [Card]
}

struct Card: Decodable, Identifiable {
    
    let id: String
    let front: String
    let back: String
    let notes: String
    
    var searchText: String {
        return front.lowercased() + " " + back.lowercased() + " " + notes.lowercased()
    }
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case front = "front"
        case back = "back"
        case notes = "notes"
    }
}
