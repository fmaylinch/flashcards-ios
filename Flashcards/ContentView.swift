//
//  ContentView.swift
//  Flashcards
//
//  Created by Ferran Maylinch carrasco on 07.01.2024.
//

import SwiftUI


#Preview {
    ContentView().preferredColorScheme(.dark)
}


struct ContentView: View {
    
    @State private var search = ""
    @State private var filteredCards: [Card] = []
    @StateObject private var cardsFromApi = CardsFromApi()
    @StateObject private var showOptions = ShowOptions()
    @State private var isEditCardPresented = false
    
    var body: some View {
        NavigationStack {
            VStack {
                ModeButtons(showOptions: showOptions)
                    .padding(.horizontal, 40)
                                
                List(filteredCards) { card in
                    CardItemView(card: card, showOptions: showOptions)
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
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isEditCardPresented.toggle()
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $isEditCardPresented) {
                    CardEditView(isPresented: $isEditCardPresented)
                }
            }
        }
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
        NavigationLink(value: card) {
            VStack(alignment: .leading, content: {
                if showOptions.showJapanese {
                    Text(card.front)
                        .font(.system(size: 28, weight: .regular))
                }
                if showOptions.showEnglish {
                    let color: Color = showOptions.showJapanese ? .orange.opacity(0.9) : .primary
                    Text(card.back)
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(color, .red)
                }
                if showOptions.showTags {
                    Text(card.tags.joined(separator: " "))
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(.purple.opacity(0.5), .red)
                }
                if showOptions.showPlayButton && !card.files.isEmpty {
                    Image(systemName: "speaker.wave.2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .padding(.vertical, 5)
                        .foregroundColor(.cyan)
                        .onTapGesture {
                            let url = "\(Constants.baseUrl)/audio/\(card.files.randomElement()!)"
                            AudioPlayerManager.shared.playSound(from: url)
                        }
                }
            })
        }
    }
}


struct CardDetailView: View {
    
    @State private var isEditCardPresented = false
    
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
            Text(card.tags.joined(separator: " "))
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(.purple, .red)
        })
        .padding(20)
        
        HStack(spacing: 0) {
            ForEach(card.files, id: \.self) { file in
                Image(systemName: "speaker.wave.2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 5)
                    .foregroundColor(.cyan)
                    .onTapGesture {
                        let url = "\(Constants.baseUrl)/audio/\(file)"
                        AudioPlayerManager.shared.playSound(from: url)
                    }
            }
        }
        
        Spacer()
        
        Button {
            isEditCardPresented = true
        } label: {
            CustomButtonText(text: "Edit Card")
        }.sheet(isPresented: $isEditCardPresented) {
            CardEditView(
                isPresented: $isEditCardPresented,
                id: card.id,
                front: card.front,
                mainWords: card.mainWords.joined(separator: " "),
                back: card.back,
                notes: card.notes,
                tags: card.tags.joined(separator: " ")
            )
        }
    }
}


// TODO: Open this view in a modal
struct CardEditView: View {

    @Binding var isPresented: Bool
    
    @State var id: String = ""
    @State var front: String = ""
    @State var mainWords: String = ""
    @State var back: String = ""
    @State var notes: String = ""
    @State var tags: String = ""

    var body: some View {
        
        Form {
            MultilineTextField(text: $front, placeholder: "Japanese", color: .primary)
            MultilineTextField(text: $mainWords, placeholder: "Main words", color: .primary.opacity(0.7))
            MultilineTextField(text: $back, placeholder: "English", color: .orange.opacity(0.9))
            MultilineTextField(text: $notes, placeholder: "Notes", color: .primary.opacity(0.7))
            TextField("Tags", text: $tags)
                .padding(.all, 8)
                .font(.system(size: 25, weight: .regular))
                .foregroundColor(.purple)
        }
            
        CustomButton(text: id.isEmpty ? "Create Card" : "Save Card") {
            print("Saving card")
            // TODO: If the card has id, then save it, otherwise create it
            isPresented.toggle()
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


// https://www.appsloveworld.com/swift/100/110/swiftui-how-can-a-textfield-increase-dynamically-its-height-based-on-its-conten

struct MultilineTextField: View {
    
    @Binding var text: String
    var placeholder: String
    var color: Color

    var body: some View {
        ZStack(alignment: .leading) {
            Text(text.isEmpty ? placeholder : text)
                .opacity(text.isEmpty ? 1 : 0)
                .padding(.all, 8) // how to allign this correctly?
                .font(.system(size: 25, weight: .regular))
                .foregroundColor(.gray.opacity(0.6)) // TODO - what's the default placeholder color?
            TextEditor(text: $text)
                .font(.system(size: 25, weight: .regular))
                .foregroundColor(color)
        }
    }
}
