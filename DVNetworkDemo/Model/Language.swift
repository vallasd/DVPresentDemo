//
//    HuckleberryNetwork  (framework for making Network requests)
//
//    Allows user to easily make Network requests (with pagination)
//
//    The MIT License (MIT)
//
//    Copyright (c) 2018 David C. Vallas (david_vallas@yahoo.com) (dcvallas@twitter)
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE

import Foundation
import HGCodable
import HGReport

struct Language: Encodable {
    let name: String
    let repositories: [Repository]
}

extension Language: HGCodable {
    
    static var encodeError: Language {
        return Language(name: "Error", repositories: [])
    }
    
    var encode: Any {
        var dict = HGDICT()
        dict["language"] = name
        dict["repositories"] = repositories.encode
        return dict
    }
    
    static func decode(object: Any) -> Language {
        let dict = HG.decode(hgdict: object, decoder: Language.self)
        let name = dict["language"].string(withDefault: "Unknown")
        let repository = Repository.decode(object: object)
        return Language(name: name, repositories: [repository])
    }
    
    /// Attempts to decode an object into an array of objects of Type HGCodable.  Returns empty array an reports Error if unable to make an array.
    static func decode(object: Any) -> [Language] {
        
        guard let a = object as? HGARRAY else {
            HGReport.shared.decodeFailed(HGARRAY.self, object: object)
            return []
        }
        
        var parsed: [Language] = []
        
        // parse JSON
        for dict in a {
            let language: Language = decode(object: dict)
            parsed.append(language)
        }
        
        let emptyArray: [TempLanguage] = []
        let combined = emptyArray.combine(languages: parsed)
        
        return combined.copy
    }
}

extension Array where Iterator.Element == Language {
    
    var repositoryCount: Int {
        var count = 0
        for language in self {
            count += language.repositories.count
        }
        return count
    }
    
    var combined: [Language] {
        let combined = self.combine(languages: [])
        let repoSorted = combined.sortedRepos
        let starSorted = repoSorted.sortedStars
        return starSorted.copy
    }
    
    func combine(withLanguages: [Language]) -> [Language] {
        let combined = self.combine(languages: withLanguages)
        let repoSorted = combined.sortedRepos
        let starSorted = repoSorted.sortedStars
        return starSorted.copy
    }
    
    fileprivate var mutableCopy: [TempLanguage] {
        var copy: [TempLanguage] = []
        for l in self {
            copy.append(TempLanguage(name: l.name, repositories: l.repositories))
        }
        return copy
    }
    
    fileprivate func combine(languages: [Language]) -> [TempLanguage] {
        
        var currentLanguages = self.map { $0.name }
        var copy = self.mutableCopy
        
        for language in languages {
            if let index = copy.firstIndex(where: { $0.name == language.name }) {
                copy[index].repositories.append(contentsOf: language.repositories)
            } else {
                currentLanguages.append(language.name)
                let newLanguage = TempLanguage(name: language.name, repositories: language.repositories)
                copy.append(newLanguage)
            }
        }
        
        return copy
    }
}

fileprivate struct TempLanguage {
    let name: String
    var repositories: [Repository]
}

extension Array where Iterator.Element == TempLanguage {
    
    var copy: [Language] {
        var copy: [Language] = []
        for temp in self {
            copy.append(Language(name: temp.name, repositories: temp.repositories))
        }
        return copy
    }
    
    var mutableCopy: [TempLanguage] {
        var mcopy: [TempLanguage] = []
        for temp in self {
            mcopy.append(TempLanguage(name: temp.name, repositories: temp.repositories))
        }
        return mcopy
    }
    
    func combine(languages: [Language]) -> [TempLanguage] {
        
        var currentLanguages = self.map { $0.name }
        var mcopy = self.mutableCopy
        
        for language in languages {
            if let index = mcopy.firstIndex(where: { $0.name == language.name }) {
                mcopy[index].repositories.append(contentsOf: language.repositories)
            } else {
                currentLanguages.append(language.name)
                let newLanguage = TempLanguage(name: language.name, repositories: language.repositories)
                mcopy.append(newLanguage)
            }
        }
        
        return mcopy
    }
    
    var sortedRepos: [TempLanguage] {
        return self.sorted(by: { $0.repositories.count > $1.repositories.count })
    }
    
    var sortedStars: [TempLanguage] {
        var index = 0
        var languages = self
        for language in self {
            let sortedRepos = language.repositories.sorted(by: { $0.stars > $1.stars })
            languages[index].repositories = sortedRepos
            index += 1
        }
        return languages
    }
}

