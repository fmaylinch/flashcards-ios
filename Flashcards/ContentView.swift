//
//  ContentView.swift
//  Flashcards
//
//  Created by Ferran Maylinch carrasco on 07.01.2024.
//

import SwiftUI

struct ContentView: View {
    
    @State private var search: String = ""
    @State private var filteredCards: [Card] = []
    @StateObject private var cardsFromApi = CardsFromApi()
    
    var body: some View {
        NavigationStack {
            VStack {
                List(filteredCards) { card in
                    VStack {
                        Text(card.front).font(.title2)
                        Text(card.back).font(.title3)
                    }
                }
                .searchable(text: $search)
                .onChange(of: search, initial: false, filterCards)
                .task {
                    do {
                        try await cardsFromApi.fetch()
                        filterCards()
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
    
    private func filterCards() {
        if search.isEmpty {
            filteredCards = cardsFromApi.cards
            return
        }
        filteredCards = cardsFromApi.cards.filter { card in
            card.back.contains(search)
        }
    }
}

#Preview {
    ContentView()
}
