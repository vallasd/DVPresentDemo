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

import UIKit
import DVNetwork

enum TVCType {
    case paging
    case alert
    case allPages
}

class SearchTVC: UITableViewController {
    
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tvcTypeControl: UISegmentedControl!
    fileprivate var tvcType: TVCType = .paging
    fileprivate var spinner: UIActivityIndicatorView!
    fileprivate var pages: [PagingData] = []
    fileprivate var searchText: String = ""
    
    fileprivate var model1: [Repository] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    fileprivate var model2: [Language] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.allowsSelection = false
        tvcTypeControl.addTarget(self, action: #selector(updateTVCType) , for: .valueChanged)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let vc = segue.destination
        
        if let rvc = vc as? RepositoryTVC {
            if let row = tableView.indexPathsForSelectedRows?.first?.row {
                let language = model2[row]
                rvc.title = language.name
                rvc.model = language.repositories
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch tvcType {
        case .paging: return 130.0
        default: return 80.0
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tvcType {
        case .paging: return model1.count
        default: return model2.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch tvcType {
        case .paging:
            let row = indexPath.row
            let cell = tableView.dequeueReusableCell(withIdentifier: "RepositoryCell") as! RepositoryCell
            let repo = model1[row]
            cell.update(withRepository: repo)
            pagingRequestForCell(atRow: row)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell") as! LanguageCell
            let language = model2[indexPath.row]
            cell.update(withLanguage: language)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "pushToRepository", sender: self)
    }
    
    fileprivate func pagingRequestForCell(atRow: Int) {
        guard let nextPage = pages.last else { return }
        let itemToKickOffNextPageRequest = nextPage.startingItemIndex - 20
        if atRow == itemToKickOffNextPageRequest {
            pages.removeLast()
            GithubNetwork.shared.getRepositories(user: searchText, pagingData: nextPage, completion: { [weak self] (result: DVResult<[Repository]>) in
                DispatchQueue.main.async {
                    self?.finishedRequest()
                    switch result {
                    case let .value(x):
                        self?.model1.append(contentsOf: x)
                    case let .error(error): self?.display(error: error)
                    }
                }
            })
        }
    }
    
    fileprivate func pagingRequest(forText: String) {
        GithubNetwork.shared.getRepositories(user: forText) { [weak self] (result: DVResultWithPagingData<[Repository]>) in
            DispatchQueue.main.async {
                self?.finishedRequest()
                switch result {
                case let .value(x):
                    self?.model1 = x.value
                    let nextPage = x.pagingData?.increment
                    self?.pages = nextPage?.indexedPages ?? []
                case let .error(error): self?.display(error: error)
                }
            }
        }
    }
    
    fileprivate func allRequest(forText: String, pagingData: PagingData?) {
        guard let pd = pagingData else { return }
        GithubNetwork.shared.getRepositories(user: searchText, pagingData: pd, completion: { [weak self] (result: DVResult<[Language]>) in
            DispatchQueue.main.async {
                self?.finishedRequest()
                switch result {
                case let .value(x): self?.model2 = self!.model2.combine(withLanguages: x)
                case let .error(error): self?.display(error: error)
                }
            }
        })
    }
    
    fileprivate func alertOrAllRequest(forText: String) {
        GithubNetwork.shared.getRepositories(user: forText) { [weak self] (result: DVResultWithPagingData<[Language]>) in
            DispatchQueue.main.async {
                guard let s = self else { return }
                s.finishedRequest()
                switch result {
                case let .value(x):
                    switch s.tvcType {
                    case .alert:
                        s.model2 = x.value
                        s.userAlert(fromPagingData: x.pagingData)
                    default:
                        s.model2 = x.value
                        let nextPage = x.pagingData?.increment
                        s.allRequest(forText: forText, pagingData: nextPage)
                    }
                case let .error(error): s.display(error: error)
                }
            }
        }
    }
    
    @objc fileprivate func updateTVCType() {
        switch tvcTypeControl.selectedSegmentIndex {
        case 0: tvcType = .paging
        case 1: tvcType = .alert
        default: tvcType = .allPages
        }
        resetTVC()
    }
    
    fileprivate func display(error: Error) {
        resetTVC()
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    fileprivate func finishedRequest() {
        stopSpinner()
        searchBar.resignFirstResponder()
    }
    
    fileprivate func resetSearch() {
        pages = []
        searchBar.text = ""
        searchText = ""
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
    }
    
    fileprivate func resetTVC() {
        switch tvcType {
        case .paging:
            tableView.allowsSelection = false
        default:
            tableView.allowsSelection = true
        }
        finishedRequest()
        resetSearch()
        if model1.count > 0 { model1 = [] }
        if model2.count > 0 { model2 = [] }
    }
    
    fileprivate func addSpinner() {
        
        if spinner == nil {
            spinner = UIActivityIndicatorView(style: .gray)
            spinner.frame = CGRect(x: 0, y: 0, width: 80.0, height: 80.0)
            spinner.center = CGPoint(x: view.bounds.width / 2.0, y: view.bounds.height / 2.0)
            spinner.style = .whiteLarge
            spinner.color = .gray
            view.addSubview(spinner)
        }
        
        spinner.isHidden = false
        spinner.startAnimating()
    }
    
    fileprivate func stopSpinner() {
        if spinner != nil {
            spinner.stopAnimating()
            spinner.isHidden = true
        }
    }
    
    /// action sheet that will ask user if he wants to download remaining repositories
    fileprivate func userAlert(fromPagingData pd: PagingData?) {
        guard let pd = pd?.increment else { return }
        let numberItemsLeft = pd.itemsLeftToDownload
        if numberItemsLeft == 0 { return }
        let title = "There are more repositories to download."
        let message = "There are up to \(numberItemsLeft) repositories left to download.  Do you want to download them?"
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] action in
            self?.allRequest(forText: self!.searchText, pagingData: pd)
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { [weak self] action in
            self?.resetSearch()
        }))
        present(alert, animated: true)
    }
}

extension SearchTVC: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.becomeFirstResponder()
        searchBar.showsCancelButton = true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // do nothing
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        searchBar.showsCancelButton = false
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        if let text = searchBar.text {
            if text != "" && text != searchText {
                addSpinner()
                pages = []
                searchText = text
                switch tvcType {
                case .paging:   pagingRequest(forText: text)
                default: alertOrAllRequest(forText: text)
                }
            }
        }
    }
    
    
}
