import SwiftUI

struct CardEditView: View {
    
    @Binding var isPresented: Bool

    var id: String = ""
    var isCreatingCard: Bool {
        return id.isEmpty
    }
    @State var front: String = ""
    @State var mainWords: String = ""
    @State var back: String = ""
    @State var notes: String = ""
    @State var tags: String = ""

    var onUpdateCard: (Card, CardUpdateAction) async -> Void

    @State private var isCallingPlay = false
    @State private var isCallingAnalyze = false
    @State private var isCallingAlter = false
    @State private var isAlertPresented = false
    @State private var isDeleteConfirmationPresented = false
    @State private var alertMessage = ""

    var body: some View {
        
        Form {
            MultilineTextField(text: $front, placeholder: "Japanese", color: .primary)
            
            HStack {
                ActionButton(imageName: "speaker.wave.2", isCallingApi: isCallingPlay) {
                    Task {
                        await playAudio(text: front)
                    }
                }
                ActionButton(imageName: "arrowshape.down", isCallingApi: isCallingAnalyze) {
                    Task {
                        await analyze(text: front)
                    }
                }
                ActionButton(imageName: "wand.and.stars", isCallingApi: isCallingAlter) {
                    Task {
                        await alterSentence(text: front)
                    }
                }
            }
            .padding(.vertical, 5)

            MultilineTextField(text: $back, placeholder: "English", color: .orange.opacity(0.9))
            MultilineTextField(text: $mainWords, placeholder: "Main words", color: .primary.opacity(0.7))
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
        isCallingPlay = true
        await tryOrAlert {
            try await CardsService.shared.generateAndPlayAudio(text: front)
        }
        isCallingPlay = false
    }
    
    func analyze(text: String) async {
        if cleanString(text).isEmpty {
            return
        }
        isCallingAnalyze = true
        await tryOrAlert {
            let prompt = "From a Japanese sentence, I want the English translation and the main words in Japanese.\nThe answer must be in JSON format, with fields \"translation\" and \"mainWords\".\nFor the 'mainWords', only include the most important words of the sentence, do not include particles, markers, or words that appear frequently in Japanese sentences. \nHere's the Japanese sentence: \(text)"
            let gptAnalyzeAnswer = try await OpenAIService().send(prompt: prompt, answerType: GptAnalyzeAnswer.self)
            back = gptAnalyzeAnswer.translation
            mainWords = gptAnalyzeAnswer.mainWords.joined(separator: "、")
        }
        isCallingAnalyze = false
    }

    func alterSentence(text: String) async {
        isCallingAlter = true
        await tryOrAlert {
            let prompt: String
            var temperature: Double? = nil
            
            // Option for custom instructions
            let gptPrefix = "gpt "
            if notes.hasPrefix(gptPrefix) {
                var instructions = notes.dropFirst(gptPrefix.count)
                // Temperature might be indicated like this: "gpt 2.0 <instructions>"
                if let customTemperature = Double(instructions.prefix(3)) {
                    temperature = customTemperature
                    instructions = instructions.dropFirst(4)
                }
                if text.isEmpty {
                    prompt = "Tell me this: \(instructions). Write the answer in Japanese, in JSON format with the Japanese text in the field \"phrase\""
                } else {
                    prompt = "I will give you a Japanese sentence, and you have do the following: \(instructions). Answer in JSON format with the answer in the field \"phrase\". The Japanese sentence is: \(text)"
                }
            } else {
                if cleanString(text).isEmpty {
                    return
                }
                prompt = "I will give you a Japanese sentence. Give me a modified version of this sentence, changing some parts of it, for example words, verb, tense, etc. Answer in JSON format with field \"phrase\". The Japanese sentence is: \(text)"
            }
            
            let gptAlterAnswer = try await OpenAIService().send(
                prompt: prompt,
                temperature: temperature,
                answerType: GptAlterAnswer.self)
            
            front = gptAlterAnswer.phrase
        }
        isCallingAlter = false
    }

    func deleteCard() async {
        await tryOrAlert {
            let deletedCard = try await CardsService.shared.deleteCard(id: id)
            await onUpdateCard(deletedCard, .delete)
            isPresented = false
        }
    }
    
    func createOrSaveCard() async {
        await tryOrAlert {
            let card = Card(
                id: id,
                front: cleanString(front),
                back: cleanString(back),
                mainWords: cleanString(mainWords).split(usingRegex: "[ 、,]+"),
                notes: cleanString(notes),
                tags: cleanString(tags).split(usingRegex: "[ ,]+"),
                files: [], // not used
                searchText: "" // not used
            )
            if isCreatingCard {
                let createdCard = try await CardsService.shared.create(card: card)
                await onUpdateCard(createdCard, .create)
            } else {
                let updatedCard = try await CardsService.shared.update(card: card)
                await onUpdateCard(updatedCard, .update)
            }
            isPresented = false
        }
    }
    
    func tryOrAlert(_ action: () async throws -> Void) async {
        do {
            try await action()
        } catch {
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

struct GptAnalyzeAnswer: Codable {
    let translation: String
    let mainWords: [String]
}

struct GptAlterAnswer: Codable {
    let phrase: String
}
