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
                ModeButtons(mode: $mode)
                    .padding(.horizontal, 40)
                                
                List(filteredCards) { card in
                    CardItemView(card: card, mode: mode)
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
                    CardEditView()
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

struct ModeButtons: View {
    
    @Binding var mode: Int
    
    var body: some View {
        HStack {
            Button {
                mode = 0
            } label: {
                Text("🇯🇵").font(.system(size: 40, weight: .regular))
            }
            Spacer()
            Button {
                mode = 1
            } label: {
                Text("🌍").font(.system(size: 40, weight: .regular))
            }
            Spacer()
            Button {
                mode = 2
            } label: {
                Text("🇬🇧").font(.system(size: 40, weight: .regular))
            }
        }
    }
}


struct CardItemView: View {
    
    var card: Card
    var mode: Int

    var body: some View {
        NavigationLink(value: card) {
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
                if !card.files.isEmpty {
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
        
        NavigationLink {
            CardEditView(
                id: card.id,
                front: card.front,
                mainWords: card.mainWords.joined(separator: "、"),
                back: card.back,
                notes: card.notes,
                tags: card.tags.joined(separator: " ")
            )
        } label: {
            CustomButtonText(text: "Edit Card")
        }
    }
}


// TODO: Open this view in a modal
struct CardEditView: View {
    
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
            print("Saving card - TODO")
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
            TextEditor(text: $text)
                .font(.system(size: 25, weight: .regular))
                .foregroundColor(color)
            Text(text.isEmpty ? placeholder : text)
                .opacity(text.isEmpty ? 1 : 0)
                .padding(.all, 8) // how to allign this correctly?
                .font(.system(size: 25, weight: .regular))
                .foregroundColor(.gray.opacity(0.6)) // TODO - what's the default placeholder color?
        }
    }
}
