//
//  Models.swift
//  Flashcards
//
//  Created by Ferran Maylinch carrasco on 08.01.2024.
//

import Foundation

@MainActor
class CardsModel: ObservableObject {
    
    @Published var cards: [Card] = []
    @Published var loaded = false
    
    func fetch(forceReload: Bool) async throws -> Bool {
        if loaded && !forceReload {
            return false
        }
        loaded = false
        let cardsResponse = try await CardsService.shared.call(method: "GET", path: "cards/list", returnType: CardsResponse.self)
        self.cards = cardsResponse.cards.reversed()
        // self.cards = [errorCard(error: error)]
        
        self.loaded = true
        return true
    }
    
    func updateCard(_ card: Card, updateAction: CardUpdateAction) {
        switch updateAction {
        case .create:
            print("Inserting new card \(card.front)")
            cards.insert(card, at: 0)
        case .update:
            if let index = cards.firstIndex(where: { $0.id == card.id }) {
                print("Replacing card \(card.front) at index \(index)")
                cards[index] = card
            } else {
                print("card \(card.id!) not found")
            }
        case .delete:
            if let index = cards.firstIndex(where: { $0.id == card.id }) {
                print("Removing card \(card.front) at index \(index)")
                cards.remove(at: index)
            } else {
                print("card \(card.id!) not found")
            }
        }
    }
}

enum CardUpdateAction {
    case create
    case update
    case delete
}

struct CardsResponse: Decodable {
    let cards: [Card]
}

struct Card: Encodable, Decodable, Identifiable, Hashable {
    
    let id: String? // This is nil when creating the card
    let front: String
    let back: String
    let mainWords: [String]
    let notes: String
    let tags: [String]
    let files: [String]? // This is nil when creating the card 
    let tts: Bool

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
        case tts = "tts"
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
        files: [],
        tts: false
    )
}
