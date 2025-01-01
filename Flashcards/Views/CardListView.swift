import SwiftUI

struct CardListView: View {
    
    @State private var search = ""
    @StateObject private var cardsModel = CardsModel()
    @State private var cardsLoaded = false
    @StateObject private var showOptions = ShowOptions()
    @State private var isEditCardPresented = false

    private var filteredCards: [Card] {
        if search.isEmpty {
            return cardsModel.cards
        } else {
            return cardsModel.cards.filter { card in
                card.searchText.localizedCaseInsensitiveContains(search)
            }
        }

    }

    var body: some View {
        VStack {
            ModeButtons(showOptions: showOptions)
                .padding(.horizontal, 40)
            
            HStack {
                Spacer()
                let cardCount = search.isEmpty ? "\(filteredCards.count)" : "\(filteredCards.count) / \(cardsModel.cards.count)"
                Text(cardsLoaded ? "\(cardCount) cards" : "loading cards")
                    .foregroundColor(.gray)
                    .padding(.trailing, 25)
            }
                            
            List(filteredCards) { card in
                NavigationLink {
                    CardDetailView(card: card) { (card, action) in
                        DispatchQueue.main.async { // TODO: where to put these main.async ?
                            cardsModel.updateCard(card, updateAction: action)
                        }
                    }

                } label: {
                    CardItemView(card: card, showOptions: showOptions)
                }
            }
            .searchable(text: $search)
            .animation(.default, value: search)
            .task {
                await loadCards(forceReload: false)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        cardsModel.cards.shuffle()
                    } label: {
                        ToolbarIcon(systemName: "shuffle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await loadCards(forceReload: true)
                        }
                    } label: {
                        ToolbarIcon(systemName: "arrow.circlepath")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isEditCardPresented.toggle()
                    } label: {
                        ToolbarIcon(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isEditCardPresented) {
                // TODO: when coming from this sheet, the List is not updated
                //   because the .task is not called.
                // When coming from CardDetailView (after editing the card),
                //   the list is updated because .task is called.
                CardEditView(isPresented: $isEditCardPresented) { (card, action) in
                    DispatchQueue.main.async {
                        cardsModel.updateCard(card, updateAction: action)
                    }
                }
            }
        }
    }
    
    // TODO: move this method to a better place, e.g. cardsModel
    private func loadCards(forceReload: Bool) async {
        if cardsLoaded && !forceReload {
            return
        }
        do {
            cardsLoaded = false
            let cards = try await CardsService.shared.getCards() // getDummyCards()
            DispatchQueue.main.async {
                self.cardsModel.cards = cards.reversed()
                cardsLoaded = true
            }
        } catch {
            self.cardsModel.cards = [errorCard(error: error)]
        }
    }
}


class ShowOptions : ObservableObject {
    @Published var showJapanese = true
    @Published var showEnglish = true
    @Published var showTags = true
    @Published var showPlayButton = true
}


struct ModeButtons: View {
    
    @ObservedObject var showOptions: ShowOptions
    
    var body: some View {
        HStack {
            ToggleButton(text: "🇯🇵", isOn: $showOptions.showJapanese)
            Spacer()
            ToggleButton(text: "🇬🇧", isOn: $showOptions.showEnglish)
            Spacer()
            ToggleIconButton(image: "tag.fill", color: .purple, isOn: $showOptions.showTags)
            Spacer()
            ToggleIconButton(image: "speaker.wave.2", color: .cyan, isOn: $showOptions.showPlayButton)
        }
    }
}

struct ToggleButton: View {
    let text: String
    @Binding var isOn: Bool
    
    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            Text(text)
                .font(.system(size: 40, weight: .regular))
                .opacity(isOn ? 1 : 0.3)
        }
    }
}

struct ToggleIconButton: View {
    let image: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            Image(systemName: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
                .foregroundColor(color)
                .opacity(isOn ? 1 : 0.3)
        }
    }
}

struct CardItemView: View {
    
    var card: Card
    @ObservedObject var showOptions: ShowOptions

    var body: some View {
        VStack(alignment: .leading, content: {
            if showOptions.showJapanese {
                Text(card.front)
                    .font(.system(size: 28, weight: .regular))
            }
            if showOptions.showEnglish {
                let color: Color = showOptions.showJapanese ? .orange.opacity(0.9) : .primary
                Text(card.back)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(color)
            }
            if showOptions.showTags {
                Text(card.tags.joined(separator: " "))
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.purple.opacity(0.5))
            }
            if showOptions.showPlayButton && !card.files.isEmpty {
                Image(systemName: "speaker.wave.2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .padding(.vertical, 5)
                    .foregroundColor(.cyan)
                    .onTapGesture {
                        Task {
                            try await CardsService.shared.playCardFile(
                                card: card,
                                fileIndex: card.files.indices.randomElement()!
                            )
                        }
                    }
            }
        })
    }
}

struct ToolbarIcon: View {
    
    var systemName: String
    
    var body: some View {
        Image(systemName: systemName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 20, height: 20)
            .foregroundColor(.cyan)
    }
}

