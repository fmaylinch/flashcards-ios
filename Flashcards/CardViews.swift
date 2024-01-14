//
//  CardViews.swift
//  Flashcards
//
//  Created by Ferran Maylinch carrasco on 14.01.2024.
//

import SwiftUI


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


struct CardEditView: View {

    @Binding var isPresented: Bool
    
    @State var id: String = ""
    @State var front: String = ""
    @State var mainWords: String = ""
    @State var back: String = ""
    @State var notes: String = ""
    @State var tags: String = ""
    
    @State private var playing = false
    
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        
        let card = messageCard(front: front, back: back) // we just need to pass `front`, actually
        
        Form {
            MultilineTextField(text: $front, placeholder: "Japanese", color: .primary)
            ZStack {
                Image(systemName: "speaker.wave.2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .padding(.vertical, 5)
                    .foregroundColor(.cyan)
                    .opacity(playing ? 0.3 : 1)
                    .onTapGesture {
                        playing = true
                        apiPost(data: card, path: "cards/tts", returnType: Card.self) { result in
                            do {
                                let file = try result.get().files[0]
                                apiPlay(file: file)
                            } catch {
                                alertMessage = "Error: \(error)"
                                showAlert = true
                            }
                            playing = false
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
        .alert("Alert", isPresented: $showAlert) {
            Button("OK") {
                showAlert = false
            }
        } message: {
            Text(alertMessage)
        }
            
        CustomButton(text: id.isEmpty ? "Create Card" : "Save Card") {
            print("Saving card")
            // TODO: If the card has id, then save it, otherwise create it
            isPresented.toggle()
        }
    }
}
