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
import DVNetwork
import HGCodable

class GithubNetwork {
    
    static let shared = GithubNetwork()
    
    let baseurl = "https://api.github.com/"
    let itemsPerPage = 100
    
    /// Gets repositories and decodes them into an array of your supplied HGCodable object.  Also, returns the PagingData for this specific request.
    func getRepositories<T: HGCodable>(user u: String, completion: @escaping (DVResultWithPagingData<[T]>) -> ()) {
        let urlString = baseurl + "users/\(u)/repos?per_page=\(itemsPerPage)"
        let requestData = RequestData(baseURL: urlString)
        DVNetwork.shared.performRequest(requestData: requestData) { (results) in
            completion(results)
        }
    }
    
    /// Gets repositories and decodes them into an array of your supplied HGCodable object.  This function will request data for all pages you request in paging data.  Completion handler will be called multiple times if the paging data has multiple pages. (uses current and last to determine what pages to grab)
    func getRepositories<T: HGCodable>(user u: String, pagingData: PagingData, completion: @escaping (DVResult<[T]>) -> ()) {
        let urlString = baseurl + "users/\(u)/repos?per_page==\(itemsPerPage)"
        let requestData = RequestData(baseURL: urlString, pagingData: pagingData)
        DVNetwork.shared.performRequest(requestData: requestData) { (results) in
            completion(results)
        }
    }
    
    
}
