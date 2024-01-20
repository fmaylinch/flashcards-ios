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
                        await playAudio(text: front)
                    }
                }
                ActionButton(imageName: "gear", isCallingApi: isCallingOpenAI) {
                    Task {
                        await analyze(text: front)
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
                        await deleteCard()
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
                await createOrSaveCard()
            }
        }
    }
    
    func playAudio(text: String) async {
        if cleanString(text).isEmpty {
            return
        }
        isCallingApiPlay = true
        await tryOrAlert {
            try await CardsService.shared.generateAndPlayAudio(text: front)
        }
        isCallingApiPlay = false
    }
    
    func analyze(text: String) async {
        if cleanString(text).isEmpty {
            return
        }
        isCallingOpenAI = true
        await tryOrAlert {
            let prompt = "From a Japanese sentence, I want the English translation and the main words in Japanese.\nThe answer must be in JSON format, with fields \"translation\" and \"words\".\nFor the 'words', only include the most important words of the sentence, do not include particles, markers, or words that appear frequently in Japanese sentences. \nHere's the Japanese sentence: \(text)"
            let json = try await OpenAIService().send(message: prompt)
            let gptAnswer = try JSONDecoder().decode(GptAnswer.self, from: json.data(using: .utf8)!)
            back = gptAnswer.translation
            mainWords = gptAnswer.words.joined(separator: "、")
        }
        isCallingOpenAI = false
    }
    
    func deleteCard() async {
        await tryOrAlert {
            let deletedCard = try await CardsService.shared.call(method: "DELETE", path: "cards/\(id)", returnType: Card.self)
            updateCard(deletedCard, .delete)
            isPresented = false
        }
    }
    
    func createOrSaveCard() async {
        await tryOrAlert {
            let method = isCreatingCard ? "POST" : "PUT"
            let path = isCreatingCard ? "cards" : "cards/\(id)"
            let card = Card(
                id: isCreatingCard ? nil : id,
                front: cleanString(front),
                back: cleanString(back),
                mainWords: cleanString(mainWords).split(usingRegex: "[ 、,]+"),
                notes: cleanString(notes),
                tags: cleanString(tags).split(usingRegex: " +"),
                files: nil,
                tts: true // TODO: I think this is used in creation for now, only
            )
            
            let cardUpdated = try await CardsService.shared.call(method: method, path: path, data: card, returnType: Card.self)
            updateCard(cardUpdated, isCreatingCard ? .create : .update)
            isPresented = false
        }
    }
    
    func tryOrAlert(_ action: () async throws -> Void) async {
        do {
            try await action()
        } catch {
            // Here we assume that alertMessage and isAlertPresented are accessible within this context
            alertMessage = "Error: \(error.localizedDescription)"
            isAlertPresented = true
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
