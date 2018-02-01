//
//  ConferenceListViewController.swift
//  AweConf
//
//  Created by Matteo Crippa on 30/01/2018.
//  Copyright © 2018 Matteo Crippa. All rights reserved.
//

import UIKit
import Exteptional
import Alamofire
import SwiftyJSON
import SwipeMenuViewController

class ConferenceListViewController: BaseViewController {
    
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var swipeMenuView: SwipeMenuView! {
        didSet {
            swipeMenuView.delegate                          = self
            swipeMenuView.dataSource                        = self
            var options: SwipeMenuViewOptions               = .init()
            options.tabView.style                           = .flexible
            options.tabView.margin                          = 8.0
            options.tabView.underlineView.backgroundColor   = UIColor.awesomeColor
            options.tabView.backgroundColor                 = .white
            options.tabView.underlineView.height            = 3.0
            options.tabView.itemView.textColor              = UIColor.awesomeColor
            options.tabView.itemView.selectedTextColor      = UIColor.awesomeColor
            options.tabView.itemView.margin                 = 10.0
            options.contentScrollView.backgroundColor       = UIColor.white
            swipeMenuView.reloadData(options: options)
        }
    }
    
    fileprivate var currentCategory: Category? = nil
    
    fileprivate var lastUpdate = Date()
    fileprivate var conferences: [Conference]? {
        didSet {
            table.reloadData()
        }
    }
    fileprivate var filteredConferences: [Conference]? {
        didSet {
            table.reloadData()
        }
    }
    fileprivate var categories: [Category]? {
        didSet {
            swipeMenuView.reloadData()
        }
    }
    fileprivate let searchController = UISearchController(searchResultsController: nil)
    fileprivate lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .awesomeColor
        refreshControl.addTarget(self, action: #selector(ConferenceListViewController.getRemoteData), for: .valueChanged)
        return refreshControl
    }()
    fileprivate var isSearchActive: Bool {
        return (searchController.isActive && searchController.searchBar.text != "")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set searchController
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Filter"
        searchController.searchBar.tintColor = .awesomeColor
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        
        title = "Conferences"
        
        // set extra stuff for navigation bar
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.hidesBackButton = false
        navigationItem.largeTitleDisplayMode = .always
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getRemoteData()
        
        // add refresh control
        table.refreshControl = refreshControl
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard
            let vc = segue.destination as? ConferenceDetailViewController,
            let index = table.indexPathForSelectedRow,
            let conference = getItem(index)
            else { return }
        
        // pass currently selected conference
        vc.conference = conference
        // deselect row
        table.deselectRow(at: index, animated: true)
    }
    
}

// MARK: - Networking
extension ConferenceListViewController {
    
    fileprivate func getCategories(callback: @escaping (_ success: Bool) -> Void) {
        Alamofire.request(AweConfApi.categories()).responseJSON { resp in
            switch resp.result {
            case .success(let data):
                
                let json = JSON(data)
                
                // loop categories
                for category in json["categories"].arrayValue {
                    let cat = Category(name: category.stringValue)
                    try! self.realm.write {
                        self.realm.add(cat, update: true)
                    }
                }
                callback(true)
                
            case .failure(let error):
                print("Request failed with error: \(error)")
                callback(false)
            }
        }
    }
    
    fileprivate func getConferences(callback: @escaping (_ success: Bool) -> Void) {
        Alamofire.request(AweConfApi.list()).responseJSON { resp in
            switch resp.result {
            case .success(let data):
                let json = JSON(data)
                
                // loop categories
                for conference in json["conferences"].arrayValue {
                    let conf = Conference(json: conference)
                    try! self.realm.write {
                        self.realm.add(conf, update: true)
                    }
                    
                }
                callback(true)
                
            case .failure(let error):
                print("Request failed with error: \(error)")
                callback(false)
            }
        }
    }
    
    @objc fileprivate func getRemoteData() {
        // start refreshing
        refreshControl.beginRefreshing()
        
        // show latest update
        let lastUpdateText = "⏱ last update: \(lastUpdate.toString(dateFormat: "dd/MM/yyyy @ HH:mm"))"
        refreshControl.attributedTitle = NSAttributedString(string: lastUpdateText)
        
        // sync cats
        getCategories { cats in
            if cats {
                //
                self.categories = Array(self.realm.objects(Category.self).sorted(byKeyPath: "name"))
                
                // sync conferences
                self.getConferences(callback: { conf in
                    
                    // force refresh
                    self.table.reloadData()
                    
                    // stop refreshing
                    self.refreshControl.endRefreshing()
                })
            }
        }
        
        conferences = getResults()
        
        // TODO: sync conferences
        
        // retrieve data from remote
        /*if let data = AMCApi.getData() {
         // parse json
         // populate headers
         if let data = MemoryDb.shared.data {
         // populate headers
         let sorted = data.conferences.sorted { (conf1, conf2) -> Bool in
         guard let c1 = conf1.start, let c2 = conf2.start else { return false }
         return c1 < c2
         }.filter({ conference -> Bool in
         guard let date = conference.start else { return false }
         return date >= Date()
         })
         
         MemoryDb.shared.headers = sorted.reduce([]) { (curr, conf) -> [String] in
         var tmp = curr
         if(!curr.contains(conf.yearMonth)) {
         tmp.append(conf.yearMonth)
         }
         return tmp
         }
         } else {
         MemoryDb.shared.headers = []
         }
         
         
         }*/
        
    }
}

// MARK: - Database (Memory)
extension ConferenceListViewController {
    
    func getResults() -> [Conference] {
        var data = Array(self.realm.objects(Conference.self).sorted(byKeyPath: "startDate"))
        
        if let category = currentCategory {
            data = data.filter({ conf -> Bool in
                return conf.category.contains(category)
            })
        }
        return data.filter { conf -> Bool in
            return conf.startDate >= Date()
        }
    }
    
}

// MARK: - UISearchBar Delegate
extension ConferenceListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        
        // check if search is active
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            // force clear the results first
            filteredConferences?.removeAll()
            
            // populate filtered results
            /*filteredConferences = MemoryDb.shared.data?.conferences.filter({ conf -> Bool in
             return conf.title.lowercased().contains(searchText.lowercased()) ||
             conf.address.lowercased().contains(searchText.lowercased())
             })*/
        }
        
    }
}

// MARK: - Data source
extension ConferenceListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conferences?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "conferenceCell") as! ConferenceTableViewCell
        guard
            let conference = getItem(indexPath)
            else { return cell }
        cell.setup(with: conference)
        return cell
    }
}

// MARK: - Table delegate
extension ConferenceListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showDetail", sender: self)
    }
    
    func getItem(_ index: IndexPath) -> Conference? {
        /*
         let yearMonth = MemoryDb.shared.headers[index.section]
         
         // is search active?
         var items = isSearchActive ? filteredConferences : conferences
         
         // filter if favorite is on
         if filterItems.selectedSegmentIndex == listType.favorite.hashValue {
         items = items?.filter({ proj -> Bool in
         return proj.isFavorite
         })
         }
         
         // clean items
         items = items?.filter({ conf -> Bool in
         return conf.yearMonth == yearMonth
         })
         
         return items?[index.row]*/
        return self.conferences?[index.row]
    }
}

// MARK: - Swipable Menu Delegate
extension ConferenceListViewController: SwipeMenuViewDelegate {
    func swipeMenuView(_ swipeMenuView: SwipeMenuView, didChangeIndexFrom fromIndex: Int, to toIndex: Int) {
        currentCategory = self.realm.objects(Category.self)[toIndex]
        conferences = getResults()
    }
}

// MARK: - Swipable Menu Data Source
extension ConferenceListViewController: SwipeMenuViewDataSource {
    func swipeMenuView(_ swipeMenuView: SwipeMenuView, viewControllerForPageAt index: Int) -> UIViewController {
        return UIViewController()
    }
    
    func numberOfPages(in swipeMenuView: SwipeMenuView) -> Int {
        return categories?.count ?? 0
    }
    
    func swipeMenuView(_ swipeMenuView: SwipeMenuView, titleForPageAt index: Int) -> String {
        return categories?[index].name ?? ""
    }
    
}
