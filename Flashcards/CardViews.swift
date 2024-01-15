//
//  CardViews.swift
//  Flashcards
//
//  Created by Ferran Maylinch carrasco on 14.01.2024.
//

import SwiftUI


struct CardDetailView: View {
    
    @State var card: Card
    var updateCard: (Card, CardUpdateAction) -> Void
    
    @State private var isEditCardPresented = false

    
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
            ForEach(card.files!, id: \.self) { file in
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
                updateCard: { (card, action) in
                    self.card = card
                    if action == .delete {
                        print("Go back")
                        // TODO: go back, maybe I need to use the NavigationPath
                    }
                    updateCard(card, action)
                },
                id: card.id!,
                front: card.front,
                mainWords: card.mainWords.joined(separator: " "),
                back: card.back,
                notes: card.notes,
                tags: card.tags.joined(separator: " ")
            )
        }
    }
}


struct CardEditView: View {
    
    @Binding var isPresented: Bool
    var updateCard: (Card, CardUpdateAction) -> Void

    var id: String = ""
    var isCreatingCard: Bool {
        return id.isEmpty
    }
    @State var front: String = "猫だ"
    @State var mainWords: String = ""
    @State var back: String = ""
    @State var notes: String = ""
    @State var tags: String = ""
    
    @State private var callingApi = false
    @State private var isAlertPresented = false
    @State private var isDeleteConfirmationPresented = false
    @State private var alertMessage = ""

    var body: some View {
        
        Form {
            MultilineTextField(text: $front, placeholder: "Japanese", color: .primary)
            ZStack {
                Image(systemName: "speaker.wave.2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .padding(.vertical, 5)
                    .foregroundColor(.cyan)
                    .opacity(callingApi ? 0.3 : 1)
                    .onTapGesture {
                        if cleanString(front).isEmpty {
                            return
                        }
                        // TODO: using messageCard, but actually we just need to set `front`
                        let card = messageCard(front: front, back: back)
                        callingApi = true
                        api(method: "POST", data: card, path: "cards/tts", returnType: Card.self) { result in
                            do {
                                let file = try result.get().files![0]
                                apiPlay(file: file)
                            } catch {
                                alertMessage = "Error: \(error)"
                                isAlertPresented = true
                            }
                            callingApi = false
                        }
                    }
            }
            MultilineTextField(text: $mainWords, placeholder: "Main words", color: .primary.opacity(0.7))
            MultilineTextField(text: $back, placeholder: "English", color: .orange.opacity(0.9))
            MultilineTextField(text: $notes, placeholder: "Notes", color: .primary.opacity(0.7))
            TextField("Tags", text: $tags)
                .padding(.all, 8)
                .font(.system(size: 25, weight: .regular))
                .foregroundColor(.purple)
        }
        .alert("Alert", isPresented: $isAlertPresented) {
            Button("OK") {
                isAlertPresented = false
            }
        } message: {
            Text(alertMessage)
        }
        
        CustomButton(text: "Delete") {
            isDeleteConfirmationPresented = true
        }.confirmationDialog("Delete the card?",
                             isPresented: $isDeleteConfirmationPresented,
                             titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                callingApi = true
                
                api(method: "DELETE", path: "cards/\(id)", returnType: Card.self) { result in
                    do {
                        let deletedCard = try result.get()
                        updateCard(deletedCard, .delete)
                        isPresented = false
                    } catch {
                        alertMessage = "Error: \(error)"
                        isAlertPresented = true
                    }
                    callingApi = false
                }
            }
            Button("Cancel", role: .cancel) {
                // nothing
            }
        }
            
        // TODO: we could pass callingApi to dim/disable the button
        CustomButton(text: isCreatingCard ? "Create Card" : "Save Card") {
            
            let path = isCreatingCard ? "cards" : "cards/\(id)"
            let method = isCreatingCard ? "POST" : "PUT"
            let card = Card(
                id: isCreatingCard ? nil : id,
                front: cleanString(front),
                back: cleanString(back),
                mainWords: cleanString(mainWords).split(usingRegex: " +"),
                notes: cleanString(notes),
                tags: cleanString(tags).split(usingRegex: " +"),
                files: nil,
                tts: true // TODO: I think this is used in creation for now, only
            )
            
            api(method: method, data: card, path: path, returnType: Card.self) { result in
                callingApi = true
                do {
                    let card = try result.get()
                    updateCard(card, isCreatingCard ? .create : .update)
                    isPresented = false
                } catch {
                    alertMessage = "Error: \(error)"
                    isAlertPresented = true
                }
                callingApi = false
            }
        }
    }
}

func cleanString(_ str: String) -> String {
    return str.trimmingCharacters(in: .whitespacesAndNewlines)
}