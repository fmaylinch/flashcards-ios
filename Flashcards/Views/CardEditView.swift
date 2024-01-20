//
//  CardViews.swift
//  Flashcards
//
//  Created by Ferran Maylinch carrasco on 14.01.2024.
//

import SwiftUI

struct CardEditView: View {
    
    @Binding var isPresented: Bool
    var updateCard: (Card, CardUpdateAction) -> Void

    var id: String = ""
    var isCreatingCard: Bool {
        return id.isEmpty
    }
    @State var front: String = ""
    @State var mainWords: String = ""
    @State var back: String = ""
    @State var notes: String = ""
    @State var tags: String = ""
    
    @State private var isCallingApiPlay = false
    @State private var isCallingOpenAI = false
    @State private var isAlertPresented = false
    @State private var isDeleteConfirmationPresented = false
    @State private var alertMessage = ""

    var body: some View {
        
        Form {
            MultilineTextField(text: $front, placeholder: "Japanese", color: .primary)
            
            HStack {
                
                ActionButton(imageName: "speaker.wave.2", isCallingApi: isCallingApiPlay) {
                    Task {
                        if cleanString(front).isEmpty {
                            return
                        }
                        // TODO: using messageCard, but actually we just need to set `front`
                        let card = messageCard(front: front, back: back)
                        isCallingApiPlay = true
                        do {
                            let testCard = try await CardsService.shared.call(
                                method: "POST",
                                data: card,
                                path: "cards/tts",
                                returnType: Card.self)
                            let file = testCard.files![0]
                            CardsService.shared.playAudio(file: file)
                        } catch {
                            alertMessage = "Error: \(error.localizedDescription)"
                            isAlertPresented = true
                        }
                        isCallingApiPlay = false
                    }
                }
                
                ActionButton(imageName: "gear", isCallingApi: isCallingOpenAI) {
                    Task {
                        if cleanString(front).isEmpty {
                            return
                        }
                        isCallingOpenAI = true
                        do {
                            let message = "From a Japanese sentence, I want the English translation and the main words in Japanese.\nThe answer must be in JSON format, with fields \"translation\" and \"words\".\nFor the 'words', only include the most important words of the sentence, do not include particles, markers, or words that appear frequently in Japanese sentences. \nHere's the Japanese sentence: \(front)"
                            let json = try await OpenAIService().send(message: message)
                            let gptAnswer = try JSONDecoder().decode(GptAnswer.self, from: json.data(using: .utf8)!)
                            back = gptAnswer.translation
                            mainWords = gptAnswer.words.joined(separator: " ")
                        } catch {
                            alertMessage = "Error: \(error.localizedDescription)"
                            isAlertPresented = true
                        }
                        isCallingOpenAI = false
                    }
                }

            }
            .padding(.vertical, 5)

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
        
        if !isCreatingCard {
            CustomButton(text: "Delete", color: .red) {
                isDeleteConfirmationPresented = true
            }.confirmationDialog("Delete the card?",
                                 isPresented: $isDeleteConfirmationPresented,
                                 titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            let deletedCard = try await CardsService.shared.call(method: "DELETE", path: "cards/\(id)", returnType: Card.self)
                            updateCard(deletedCard, .delete)
                            isPresented = false
                        } catch {
                            alertMessage = "Error: \(error.localizedDescription)"
                            isAlertPresented = true
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    // nothing
                }
            }
        }
            
        // TODO: we could pass callingApi to dim/disable the button
        CustomButton(text: isCreatingCard ? "Create Card" : "Save Card") {
            Task {
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
                
                do {
                    let card = try await CardsService.shared.call(method: method, data: card, path: path, returnType: Card.self)
                    updateCard(card, isCreatingCard ? .create : .update)
                    isPresented = false
                } catch {
                    alertMessage = "Error: \(error.localizedDescription)"
                    isAlertPresented = true
                }
            }
        }
    }
}

func cleanString(_ str: String) -> String {
    return str.trimmingCharacters(in: .whitespacesAndNewlines)
}

struct ActionButton: View {
    let imageName: String
    let isCallingApi: Bool
    let action: () -> Void

    var body: some View {
        Image(systemName: imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 30, height: 30)
            .foregroundColor(.cyan)
            .opacity(isCallingApi ? 0.3 : 1)
            .padding(.trailing, 20)
            .onTapGesture { action() } // I had problems using Button callback
    }
}

struct GptAnswer: Decodable {
    let translation: String
    let words: [String]
    
    private enum CodingKeys: String, CodingKey {
        case translation = "translation"
        case words = "words"
    }
}
