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
        do {
            let cardsResponse = try await apiGet(path: "cards/list", returnType: CardsResponse.self)
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

struct Card: Encodable, Decodable, Identifiable, Hashable {
    
    let id: String?
    let front: String
    let back: String
    let mainWords: [String]
    let notes: String
    let tags: [String]
    let files: [String]? // TODO: This is nil when creating the card 
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
