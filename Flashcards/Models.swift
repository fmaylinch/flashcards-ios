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
    var loaded = false
    
    func fetch(forceReload: Bool) async {
        if loaded && !forceReload {
            print("Cards already loaded")
            return
        }
        loaded = false
        let url = "\(Constants.baseUrl)/cards/list"
        var request = URLRequest(url: URL(string: url)!)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // TODO: get from login
        let token = Constants.testToken
        request.addValue("Bearer: " + token, forHTTPHeaderField: "Authorization")
        
        do {
            print("Getting cards from \(url)")
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    cards = [errorCard(text: "API response code: \(httpResponse.statusCode)")]
                    return
                }
            }
            let cardsResponse = try JSONDecoder().decode(CardsResponse.self, from: data)
            cards = cardsResponse.cards.shuffled()
            loaded = true
        } catch {
            cards = [errorCard(error: error)]
        }
    }
}

struct CardsResponse: Decodable {
    let cards: [Card]
}

struct Card: Decodable, Identifiable, Hashable {
    
    let id: String
    let front: String
    let back: String
    let mainWords: [String]
    let notes: String
    let tags: [String]
    let files: [String]

    var searchText: String {
        return front.lowercased() + " " + back.lowercased() + " " + notes.lowercased() + " " + tags.joined(separator: ". ") + "."
    }
    
    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case front = "front"
        case back = "back"
        case mainWords = "mainWords"
        case notes = "notes"
        case tags = "tags"
        case files = "files"
    }
}

class CardForm: ObservableObject {
    @Published var id: String
    @Published var front: String
    @Published var back: String
    @Published var notes: String

    init() {
        self.id = ""
        self.front = ""
        self.back = ""
        self.notes = ""
    }
    
    init(card: Card) {
        self.id = card.id
        self.front = card.front
        self.back = card.back
        self.notes = card.notes
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
    return Card(
        id: "",
        front: front,
        back: back,
        mainWords: [],
        notes: "",
        tags: [],
        files: []
    )
}
