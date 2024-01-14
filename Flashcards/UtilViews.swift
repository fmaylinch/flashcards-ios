//
//  UtilViews.swift
//  Flashcards
//
//  Created by Ferran Maylinch carrasco on 14.01.2024.
//

import SwiftUI


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

