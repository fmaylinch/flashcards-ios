import Foundation

@MainActor
class CardsModel: ObservableObject {
    
    @Published var cards: [Card] = []
    
    // Updates the list of cards locally, so we don't have to call CardsService.getCards() all the time
    // TODO: move this logic as a cache in CardsService, or as a CachedCardsService proxy
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
                print("card \(card.id) not found")
            }
        case .delete:
            if let index = cards.firstIndex(where: { $0.id == card.id }) {
                print("Removing card \(card.front) at index \(index)")
                cards.remove(at: index)
            } else {
                print("card \(card.id) not found")
            }
        }
    }
}

struct Card: Identifiable, Hashable {
    let id: String
    let front: String
    let back: String
    let mainWords: [String]
    let notes: String
    let tags: [String]
    let files: [String]
    let searchText: String
}

enum CardUpdateAction {
    case create
    case update
    case delete
}

/** Dummy card to show an error message */
func errorCard(error: Error) -> Card {
    return errorCard(text: error.localizedDescription)
}

func errorCard(text: String) -> Card {
    return messageCard(front: "ごめんなさい！", back: text)
}

func messageCard(front: String, back: String = "") -> Card {
    return dummyCard(id: "", front: front, back: back)
}

func dummyCard(id: String, front: String, back: String) -> Card {
    return Card(
        id: id,
        front: front,
        back: back,
        mainWords: [],
        notes: "",
        tags: [],
        files: [],
        searchText: front + " " + back
    )
}
