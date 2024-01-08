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
    
    @State private var mode = 0
    private var modeText: String {
        return switch mode {
        case 0: "Japanese / English"
        case 1: "Japanese"
        case 2: "Japanese / English"
        case 3: "English"
        default: "(unexpected)"
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Button(modeText, action: changeMode)
                List(filteredCards) { card in
                    VStack(alignment: .leading, content: {
                        if mode != 3 {
                            Text(card.front).font(.title)
                        }
                        if mode != 1 {
                            Text(card.back).font(.title3)
                        }
                    })
                }
                .searchable(text: $search)
                .onChange(of: search, initial: false, filterCards)
                .task {
                    await cardsFromApi.fetch()
                    filterCards()
                }
            }
        }
    }
    
    private func changeMode() {
        mode = (mode + 1) % 4
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
    ContentView()
}
