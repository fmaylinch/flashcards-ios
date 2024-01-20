import SwiftUI

struct CardDetailView: View {
    
    @State var card: Card
    var updateCard: (Card, CardUpdateAction) -> Void
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
                id: isCardDeleted ? "" : card.id,
                front: card.front,
                mainWords: card.mainWords.joined(separator: "、"),
                back: card.back,
                notes: card.notes,
                tags: card.tags.joined(separator: " ")
            )
        }
    }
}


// --- Logic for clickable terms ---

struct Term: Hashable {
    let word: String
    let link: String? // if missing, we don't want to link this word
}

struct MainTextView: View {
    
    let text: String
    let mainWords: [String]
    
    var body: some View {
        //let mainWords = ["今日", "天気", "公園", "行きましょ:行く"]
        //let text = "今日はいい天気ですね。公園に行きましょか？"
        let wordsAndLinks = mainWords.isEmpty ? [text] : mainWords // by default, the whole text is a clickable term
        let mainTerms = mapToTerms(wordAndLinks: wordsAndLinks)
        let terms = split(text: text, mainTerms: mainTerms)
        let lines = split(terms: terms, maxChars: 11)

        VStack {
            ForEach(lines, id: \.self) { line in
                HStack(spacing: 0) {
                    ForEach(line, id: \.self) { term in
                        if let link = term.link {
                            Link(destination: URL(string: "https://nihongo-app.com/dictionary/word/\(link)")!) {
                                Text(term.word)
                                    .font(.system(size: 28, weight: .regular))
                                    .foregroundColor(.cyan)
                            }
                        } else {
                            Text(term.word)
                                .font(.system(size: 28, weight: .regular))
                        }
                    }
                }
            }
        }
    }
}

// Some words indicate the desired link, like this: "word:link".
// For example, from ["A", "B:linkB", "C:linkC"] returns [ ["A", "B", "C"], ["A", "linkB", "linkC"] ]
func mapToTerms(wordAndLinks: [String]) -> [Term] {
    let result = wordAndLinks.map { wordAndLink in
        let components = wordAndLink.split(separator: ":").map { String($0) }
        if components.count > 1 {
            return Term(word: components[0], link: components[1])
        } else {
            return Term(word: wordAndLink, link: wordAndLink)
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
        if let separatorRange = text.range(of: term.word) {
            let piece = String(text[currentIndex..<separatorRange.lowerBound])
            if !piece.isEmpty {
                result.append(Term(word: piece, link: nil)) // text before the term found
            }
            result.append(term)
            currentIndex = separatorRange.upperBound
        }
    }
    result.append(Term(word: String(text[currentIndex..<text.endIndex]), link: nil)) // remaining text
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
