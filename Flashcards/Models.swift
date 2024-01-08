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
    
    func fetch() async {
        let url = "http://158.160.43.18:3001/cards/list"
        var request = URLRequest(url: URL(string: url)!)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let token = "TOKEN"
        request.addValue("Bearer: " + token, forHTTPHeaderField: "Authorization")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    cards = [errorCard(text: "API response code: \(httpResponse.statusCode)")]
                    return
                }
            }
            let cardsResponse = try JSONDecoder().decode(CardsResponse.self, from: data)
            cards = cardsResponse.cards.shuffled()
        } catch {
            cards = [errorCard(error: error)]
        }
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

/** Dummy card to show an error message */
func errorCard(error: Error) -> Card {
    return errorCard(text: error.localizedDescription)
}

func errorCard(text: String) -> Card {
    return messageCard(front: "ごめんなさい！", back: text)
}

/** Dummy card to show a message */
func messageCard(front: String, back: String) -> Card {
    return Card(id: "", front: front, back: back, notes: "")
}
