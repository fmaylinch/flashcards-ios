//
//  CardDetailView.swift
//  Flashcards
//
//  Created by Ferran Maylinch carrasco on 15.01.2024.
//

import SwiftUI

struct CardDetailView: View {
    
    @State var card: Card
    var updateCard: (Card, CardUpdateAction) -> Void
    @State private var isCardDeleted: Bool = false

    @State private var isEditCardPresented = false

    
    var body: some View {
        
        Spacer()
        
        VStack(content: {
            Text(card.front)
                .font(.system(size: 28, weight: .regular))
                .padding(.bottom, 20)
            Text(card.back)
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(.orange.opacity(0.9))
                .padding(.bottom, 20)
            Text(card.notes)
                .font(.system(size: 20, weight: .regular))
                .padding(.bottom, 20)
                .foregroundColor(.gray)
            Text(card.tags.joined(separator: " "))
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(.purple)
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
        
        CustomButton(text: isCardDeleted ? "Recreate Card" : "Edit Card") {
            isEditCardPresented = true
        }.sheet(isPresented: $isEditCardPresented) {
            CardEditView(
                isPresented: $isEditCardPresented,
                updateCard: { (card, action) in
                    self.card = card
                    updateCard(card, action)
                    isCardDeleted = action == .delete
                },
                id: isCardDeleted ? "" : card.id!,
                front: card.front,
                mainWords: card.mainWords.joined(separator: " "),
                back: card.back,
                notes: card.notes,
                tags: card.tags.joined(separator: " ")
            )
        }
    }
}
