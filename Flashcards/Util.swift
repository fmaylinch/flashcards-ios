//
//  Util.swift
//  Flashcards
//
//  Created by Ferran Maylinch carrasco on 14.01.2024.
//

import Foundation

extension String {
    
    func split(usingRegex pattern: String) -> [String] {
        
        // Create the regular expression
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        
        // Find matches
        let range = NSRange(self.startIndex..<self.endIndex, in: self)
        let matches = regex.matches(in: self, options: [], range: range)
        
        var lastEnd = self.startIndex
        var result = [String]()
        
        // Extract substrings
        for match in matches {
            let range = Range(match.range, in: self)!
            let splitStart = Range(uncheckedBounds: (lower: lastEnd, upper: range.lowerBound))
            let substring = String(self[splitStart])
            result.append(substring)
            lastEnd = range.upperBound
        }
        
        // Add the final part of the string
        if lastEnd != self.endIndex {
            result.append(String(self[lastEnd...]))
        }
        
        return result
    }
}

