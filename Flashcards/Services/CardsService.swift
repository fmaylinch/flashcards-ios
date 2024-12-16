import Foundation

final class CardsService : Sendable {
    
    @MainActor static let shared = CardsService()
    
    func generateAndPlayAudio(text: String) async throws {
        let cardToListen = try await CardsService.shared.call(
            method: "POST",
            path: "cards/tts",
            data: TextToListen(front: text),
            returnType: CardToListenResponse.self)
        let file = cardToListen.files[0]
        await CardsService.shared.playAudio(file: file)
    }
    
    func playCardFile(card: Card, fileIndex: Int) async throws {
        let cardToListen = try await CardsService.shared.call(
            method: "POST",
            path: "cards/audio/\(fileIndex)",
            data: CardToListen(_id: card.id),
            returnType: CardToListenResponse.self)
        let file = cardToListen.files[0]
        await CardsService.shared.playAudio(file: file)
    }
    
    // This function should not be used directly from outside,
    // because the file to listen to is prepared via other methods.
    @MainActor private func playAudio(file: String) {
        let url = "\(Constants.baseUrl)/audio/\(Constants.username)/\(file)"
        AudioPlayerManager.shared.playSound(from: url)
    }
    
    func getCards() async throws -> [Card] {
        let cardsResponse = try await call(
            method: "GET",
            path: "cards/list",
            returnType: CardsResponse.self)
        return cardsResponse.cards.map(toModel)
    }
    
    func create(card: Card) async throws -> Card {
        let cardCreated = try await CardsService.shared.call(
            method: "POST",
            path: "cards",
            data: CardCreation(
                front: card.front,
                back: card.back,
                mainWords: card.mainWords,
                notes: card.notes,
                tags: card.tags,
                tts: true),
            returnType: CardResponse.self)
        return toModel(cardCreated)
    }

    func update(card: Card) async throws -> Card {
        let cardUpdated = try await CardsService.shared.call(
            method: "PUT",
            path: "cards/\(card.id)",
            data: CardUpdate(
                front: card.front,
                back: card.back,
                mainWords: card.mainWords,
                notes: card.notes,
                tags: card.tags),
            returnType: CardResponse.self)
        return toModel(cardUpdated)
    }
    
    func deleteCard(id: String) async throws -> Card {
        let cardDeleted = try await CardsService.shared.call(
            method: "DELETE",
            path: "cards/\(id)",
            returnType: CardResponse.self)
        return toModel(cardDeleted)
    }
        
    private func toModel(_ card: CardResponse) -> Card {
        return Card(id: card._id,
                    front: card.front,
                     back: card.back,
                     mainWords: card.mainWords,
                     notes: card.notes,
                     tags: card.tags,
                     files: card.files,
                     searchText: card.front.lowercased() + " " +
                        card.back.lowercased() + " " +
                        card.notes.lowercased() + " " +
                        card.tags.joined(separator: ". ") + "."
        )
    }
    
    private func call<T>(method: String,
                 path: String,
                 data: Encodable? = nil,
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
        //print("Making call to \(url) with data: \(data)")

        let (data, _) = try await URLSession.shared.data(for: request)
        //print("Received data: \(String(data: data, encoding: .utf8))")
        
        return try JSONDecoder().decode(returnType, from: data)
    }
}

// --- DTOs ---

struct CardsResponse: Decodable {
    let cards: [CardResponse]
}

struct CardResponse: Decodable {
    let _id: String
    let front: String
    let back: String
    let mainWords: [String]
    let notes: String
    let tags: [String]
    let files: [String]
    let tts: Bool
}

struct CardCreation: Encodable {
    let front: String
    let back: String
    let mainWords: [String]
    let notes: String
    let tags: [String]
    let tts: Bool
}

struct CardUpdate: Encodable {
    let front: String
    let back: String
    let mainWords: [String]
    let notes: String
    let tags: [String]
    // TODO: check that files and tts is not updated in the DB
}

struct TextToListen: Encodable {
    let front: String
}

struct CardToListen: Encodable {
    let _id: String
}

struct CardToListenResponse: Decodable {
    let front: String
    let files: [String]
}
