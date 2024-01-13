//
//  ContentView.swift
//  Flashcards
//
//  Created by Ferran Maylinch carrasco on 07.01.2024.
//

import SwiftUI

struct ContentView: View {
    
    @State private var search = ""
    @State private var filteredCards: [Card] = []
    @StateObject private var cardsFromApi = CardsFromApi()
    
    @State private var mode = 1
    private var modeText: String {
        return switch mode {
        case 0: "Japanese"
        case 1: "All"
        case 2: "English"
        default: "(unexpected)"
        }
    }
        
    var body: some View {
        NavigationStack {
            VStack {
                CustomButton(text: modeText) {
                    changeMode()
                }
                                
                List(filteredCards) { card in
                    NavigationLink(value: card) {
                        CardItemView(card: card, mode: mode)
                    }
                }
                .searchable(text: $search)
                .onChange(of: search, initial: false, filterCards)
                .task {
                    await cardsFromApi.fetch(forceReload: false)
                    filterCards()
                }
                .navigationTitle("List")
                .navigationDestination(for: Card.self) { card in
                    CardDetailView(card: card)
                }
                .navigationBarItems(trailing: NavigationLink {
                    CardEditView(cardForm: CardForm())
                } label: {
                    Image(systemName: "plus")
                })
            }
        }
    }
    
    private func changeMode() {
        mode = (mode + 1) % 3
    }
    
    private func filterCards() {
        if search.isEmpty {
            filteredCards = cardsFromApi.cards
            return
        }
        let searchLower = search.lowercased()
        filteredCards = cardsFromApi.cards.filter { card in
            card.searchText.contains(searchLower)
        }
    }
}

#Preview {
    let main = ContentView().preferredColorScheme(.dark)
    let detail = CardDetailView(card: Card(
        id: "123",
        front: "アニメが好きです",
        back: "I like anime",
        mainWords: ["アニメ", "好き"],
        notes: "Simple sentence",
        tags: ["phrase", "beginner"]
    )).preferredColorScheme(.dark)
    
    return main
}


struct CardItemView: View {
    
    var card: Card
    var mode: Int

    var body: some View {
        VStack(alignment: .leading, content: {
            if mode != 2 {
                Text(card.front)
                    .font(.system(size: 28, weight: .regular))
            }
            if mode != 0 {
                let color: Color = mode == 1 ? .orange.opacity(0.9) : .primary
                Text(card.back)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(color, .red)
            }
            if mode == 1 {
                Text(card.tags.joined(separator: ", "))
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.purple.opacity(0.5), .red)
            }
        })
    }
}

struct CardDetailView: View {
    
    var card: Card
    
    var body: some View {
        
        Spacer()
        
        VStack(content: {
            Text(card.front)
                .font(.system(size: 28, weight: .regular))
                .padding(.bottom, 20)
            Text(card.back)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(.orange.opacity(0.9), .red)
                .padding(.bottom, 20)
            Text(card.notes)
                .font(.system(size: 20, weight: .regular))
                .padding(.bottom, 20)
                .foregroundStyle(.gray, .red)
            Text(card.tags.joined(separator: ", "))
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(.purple, .red)
        })
        .padding(20)
        
        Spacer()
        
        NavigationLink {
            CardEditView(cardForm: CardForm(card: card))
        } label: {
            CustomButtonText(text: "Edit Card")
        }
    }
}

struct CardEditView: View {
    
    @State var cardForm: CardForm
    
    var body: some View {
        
        Form {
            TextField("Front", text: $cardForm.front)
                .font(.system(size: 25, weight: .regular))
            TextField("Back", text: $cardForm.back)
                .font(.system(size: 25, weight: .regular))
            TextField("Notes", text: $cardForm.notes)
                .font(.system(size: 25, weight: .regular))
        }
            
        CustomButton(text: cardForm.id.isEmpty ? "Create Card" : "Save Card") {
            // TODO - create or save card
        }
    }
}


struct CustomButton: View {
    
    var text: String
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            CustomButtonText(text: text)
        }
    }
}

struct CustomButtonText: View {
    
    var text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 25, weight: .regular))
            .foregroundStyle(.cyan)
    }
}
