import SwiftUI

struct CardDetailView: View {
    
    @State var card: Card
    var onUpdateCard: (Card, CardUpdateAction) async -> Void
    @State private var isCardDeleted: Bool = false

    @State private var isEditCardPresented = false

    
    var body: some View {
        
        Spacer()
        
        VStack(content: {
            
            MainTextView(text: card.front, mainWords: card.mainWords)
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
            ForEach(card.files.indices, id: \.self) { index in
                Image(systemName: "speaker.wave.2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 5)
                    .foregroundColor(.cyan)
                    .onTapGesture {
                        print("Playing file \(index) of card \(card.front), which is file \(card.files[index])")
                        Task {
                            try await CardsService.shared.playCardFile(card: card, fileIndex: index)
                        }
                    }
            }
            Image(systemName: "speaker.wave.2.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
                .padding(.horizontal, 15)
                .padding(.vertical, 5)
                .foregroundColor(.cyan)
                .onTapGesture {
                    print("Playing card \(card.front), with shortcut to use Siri voice")
                    playCardWithSiri(card: card)
                }
        }
        
        Spacer()
        
        CustomButton(text: isCardDeleted ? "Recreate Card" : "Edit Card") {
            isEditCardPresented = true
        }.sheet(isPresented: $isEditCardPresented) {
            CardEditView(
                isPresented: $isEditCardPresented,
                id: isCardDeleted ? "" : card.id,
                front: card.front,
                mainWords: card.mainWords.joined(separator: "、"),
                back: card.back,
                notes: card.notes,
                tags: card.tags.joined(separator: " ")
            ) { (card, action) in
                self.card = card
                await onUpdateCard(card, action)
                isCardDeleted = action == .delete
            }
        }
    }
}


// --- Logic for clickable terms ---

struct Term: Hashable {
    let word: String
    let color: Color
    let link: String? // if missing, we don't want to link this word
}

struct MainTextView: View {
    
    let text: String
    let mainWords: [String]
    
    var body: some View {
        let mainTerms = mapToTerms(wordAndLinks: calculateWordsAndLinks())
        let terms = split(text: text, mainTerms: mainTerms)
        let lines = split(terms: terms, maxChars: 11)
        let fontSize: CGFloat = 28
        let paddingForPunctuation = fontSize * 0.4 // it looks like the usual spacing

        VStack {
            ForEach(lines, id: \.self) { line in
                HStack(spacing: 0) {
                    ForEach(line, id: \.self) { term in
                        if let link = term.link {
                            Link(destination: URL(string: "https://nihongo-app.com/dictionary/word/\(link)")!) {
                                Text(term.word)
                                    .font(.system(size: fontSize, weight: .regular))
                                    .foregroundColor(term.color)
                            }
                        } else {
                            // Japanese punctuation last characters don't have the usual trailing padding
                            let endsInPunctuation = ["、", "。"].contains(term.word.last)
                            Text(term.word)
                                .font(.system(size: fontSize, weight: .regular))
                                .padding(.trailing, endsInPunctuation ? paddingForPunctuation : 0)
                        }
                    }
                }
            }
        }
    }
    
    private func calculateWordsAndLinks() -> [String] {
        if !mainWords.isEmpty {
            return mainWords
        }
        // By default, detect words separated by commas and dots
        return text.components(separatedBy: CharacterSet(charactersIn: "、。")).filter { !$0.isEmpty }
    }
}

// Some words indicate the desired link, like this: "word:link".
// For example, from ["A", "B:linkB", "C:linkC"] returns [ ["A", "B", "C"], ["A", "linkB", "linkC"] ]
func mapToTerms(wordAndLinks: [String]) -> [Term] {
    let colors: [Color] = [.cyan, .cyan.mix(with: .black, by: 0.2)] // to distinguish adjacent words
    var colorIndex = 0
    let result = wordAndLinks.map { wordAndLink in
        let components = wordAndLink.split(separator: ":").map { String($0) }
        let color = colors[colorIndex]
        colorIndex = (colorIndex + 1) % colors.count
        if components.count > 1 {
            return Term(word: components[0], color: color, link: components[1])
        } else {
            return Term(word: wordAndLink, color: color, link: wordAndLink)
        }
    }
    //print("mainTerms: \(result)")
    return result
}

// splits text where substrings occur (substrings should appear in the same order in text)
func split(text: String, mainTerms: [Term]) -> [Term] {
    var currentIndex = text.startIndex
    var result: [Term] = []

    for term in mainTerms {
        if let separatorRange = text.range(of: term.word, range: currentIndex ..< text.endIndex) {
            if (separatorRange.lowerBound < currentIndex) {
                continue // order of terms is probably wrong
            }
            let piece = String(text[currentIndex ..< separatorRange.lowerBound])
            if !piece.isEmpty {
                result.append(Term(word: piece, color: .white, link: nil)) // text before the term found
            }
            result.append(term)
            currentIndex = separatorRange.upperBound
        }
    }
    let remainingText = text[currentIndex ..< text.endIndex]
    if !remainingText.isEmpty {
        result.append(Term(word: String(remainingText), color: .white, link: nil))
    }
    //print("Split terms: \(result)")
    return result
}

// split list of Term into multiple lists, where each list has maxChars
func split(terms: [Term], maxChars: Int) -> [[Term]] {
    var resultList = [[Term]()]
    var currentList = [Term]()
    var currentCharCount = 0

    for term in terms {
        if (currentCharCount + term.word.count) <= maxChars {
            currentList.append(term)
            currentCharCount += term.word.count
        } else {
            resultList.append(currentList)
            currentList = [term]
            currentCharCount = term.word.count
        }
    }
    
    if !currentList.isEmpty {
        resultList.append(currentList)
    }
    
    //print("resultList: \(resultList)")
    return resultList
}

@MainActor func playCardWithSiri(card: Card) {
    guard
        // This is the name of a Shortcut I have
        let shortcut = "Text to JP audio".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
        let text = card.front.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    else {
        print("Encoding of shortcut or text failed")
        return
    }
    let urlString = "shortcuts://run-shortcut?name=\(shortcut)&input=text&text=\(text)"
    print("Opening shortcut with URL: \(urlString)")
    guard let url = URL(string: urlString) else {
        print("Malformed URL: \(urlString)")
        return
    }
    UIApplication.shared.open(url)
}


#Preview {
    CardTestView()
}

struct CardTestView: View {
    var body: some View {
        CardDetailView(
            card: Card(
                id: "",
                front: "春、夏、秋、冬",
                back: "spring, summer, autumn, winter",
                mainWords: [],
                notes: "test card",
                tags: ["weather", "time"],
                files: [],
                searchText: "")
        ) { (card, action) in
            
        }
    }
}
