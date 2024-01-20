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
                
                Image(systemName: "speaker.wave.2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundColor(.cyan)
                    .opacity(isCallingApiPlay ? 0.3 : 1)
                    .padding(.trailing, 20)
                    .onTapGesture {
                        if cleanString(front).isEmpty {
                            return
                        }
                        // TODO: using messageCard, but actually we just need to set `front`
                        let card = messageCard(front: front, back: back)
                        isCallingApiPlay = true
                        api(method: "POST", data: card, path: "cards/tts", returnType: Card.self) { result in
                            do {
                                let file = try result.get().files![0]
                                apiPlay(file: file)
                            } catch {
                                alertMessage = "Error: \(error)"
                                isAlertPresented = true
                            }
                            isCallingApiPlay = false
                        }

                    }

                Image(systemName: "gear")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .padding(.trailing, 20)
                    .foregroundColor(.cyan)
                    .opacity(isCallingOpenAI ? 0.3 : 1)
                    .onTapGesture {
                        Task {
                            if cleanString(front).isEmpty {
                                return
                            }
                            isCallingOpenAI = true
                            do {
                                let message = "From a Japanese sentence, I want the English translation and the main words in Japanese (omitting particles and markers).\nThe answer must be in JSON format, with fields \"translation\" and \"words\".\nHere's the Japanese sentence: \(front)"
                                let json = try await OpenAIService().send(message: message)
                                let gptAnswer = try JSONDecoder().decode(GptAnswer.self, from: json.data(using: .utf8)!)
                                back = gptAnswer.translation
                                mainWords = gptAnswer.words.joined(separator: " ")
                            } catch {
                                notes = error.localizedDescription
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
                    api(method: "DELETE", path: "cards/\(id)", returnType: Card.self) { result in
                        do {
                            let deletedCard = try result.get()
                            updateCard(deletedCard, .delete)
                            isPresented = false
                        } catch {
                            alertMessage = "Error: \(error)"
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
                do {
                    let card = try result.get()
                    updateCard(card, isCreatingCard ? .create : .update)
                    isPresented = false
                } catch {
                    alertMessage = "Error: \(error)"
                    isAlertPresented = true
                }
            }
        }
    }
}

func cleanString(_ str: String) -> String {
    return str.trimmingCharacters(in: .whitespacesAndNewlines)
}

struct GptAnswer: Decodable {
    let translation: String
    let words: [String]
    
    private enum CodingKeys: String, CodingKey {
        case translation = "translation"
        case words = "words"
    }
}
