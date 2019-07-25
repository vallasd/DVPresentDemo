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

struct Repository: Encodable {
    let name: String
    let desc: String
    let login: String
    let language: String
    let stars: Int
    let forks: Int
    let updated: Date
}

extension Repository: HGCodable {
    
    static var encodeError: Repository {
        return Repository(name: "Error",
                             desc: "Error",
                             login: "Error",
                             language: "Error",
                             stars: 0,
                             forks: 0,
                             updated: Date())
    }
    
    var encode: Any {
        var dict = HGDICT()
        dict["name"] = name
        dict["description"] = desc
        var ownerDict = HGDICT()
        ownerDict["login"] = login
        dict["owner"] = ownerDict
        dict["stargazers_count"] = stars
        dict["forks"] = forks
        dict["updated_at"] = updated
        dict["language"] = language
        return dict
    }
    
    static func decode(object: Any) -> Repository {
        let dict = HG.decode(hgdict: object, decoder: Repository.self)
        let name = dict["name"].string
        let desc = dict["description"].string(withDefault: "No description provided")
        let owner = dict["owner"].dict
        let login = owner["login"].string
        let stars = dict["stargazers_count"].int
        let forks = dict["forks"].int
        let updated = dict["updated_at"].date
        let language = dict["language"].string(withDefault: "Unknown")
        let repo = Repository(name: name, desc: desc, login: login, language: language, stars: stars, forks: forks, updated: updated)
        return repo
    }
}
