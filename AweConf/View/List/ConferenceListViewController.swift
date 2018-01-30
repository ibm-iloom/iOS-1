//
//  ConferenceListViewController.swift
//  AweConf
//
//  Created by Matteo Crippa on 30/01/2018.
//  Copyright © 2018 Matteo Crippa. All rights reserved.
//

import UIKit
import Exteptional

class ConferenceListViewController: BaseViewController {
    
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var filterItems: UISegmentedControl!
    
    // type of the list
    fileprivate enum listType {
        case all
        case favorite
    }
    
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
        
        // set tint of selector
        filterItems.tintColor = .awesomeColor
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
        
        
        vc.conference = conference
        table.deselectRow(at: index, animated: true)
    }
    
}

// MARK: - Networking
extension ConferenceListViewController {
    
    fileprivate func parseJson(from data: Data) {
        do {
            let decoded = try JSONDecoder().decode(Awesome.self, from: data)
            MemoryDb.shared.data = decoded
            // get all results for root
            conferences = getResults()
            //print("👨‍💻 decoded:", decoded)
        } catch (let error) {
            print("🙅 \(error)")
        }
    }
    
    @objc fileprivate func getRemoteData() {
        
        // start refreshing
        refreshControl.beginRefreshing()
        
        // show latest update
        let lastUpdate = "⏱ last update: \(MemoryDb.shared.lastUpdate.toString(dateFormat: "dd/MM/yyyy @ HH:mm"))"
        refreshControl.attributedTitle = NSAttributedString(string: lastUpdate)
        
        // retrieve data from remote
        if let data = AMCApi.getData() {
            // parse json
            parseJson(from: data)
            
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
            
            // force refresh
            table.reloadData()
            
            // stop refreshing
            refreshControl.endRefreshing()
        }
        
    }
}

// MARK: - Database (Memory)
extension ConferenceListViewController {
    
    func getResults() -> [Conference]? {
        if let data = MemoryDb.shared.data {
            // sort by start date
            return data.conferences.sorted(by: {(a, b) -> Bool in
                return a.start! < b.start!
            }).filter({ conference -> Bool in
                guard let date = conference.start else { return false }
                return date >= Date()
            })
        }
        return nil
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
            filteredConferences = MemoryDb.shared.data?.conferences.filter({ conf -> Bool in
                return conf.title.lowercased().contains(searchText.lowercased()) ||
                    conf.address.lowercased().contains(searchText.lowercased())
            })
        }
        
    }
}

// MARK: Actions
extension ConferenceListViewController {
    @IBAction func changeFilterItems(sender: UISegmentedControl) {
        //print(sender.selectedSegmentIndex)
        // reload table
        table.reloadData()
    }
}

// MARK: - Data source
extension ConferenceListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return MemoryDb.shared.headers.count
        //return MemoryDb.shared.data?.years.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let yearMonth = MemoryDb.shared.headers[section]
        
        // is search active?
        var items = isSearchActive ? filteredConferences : conferences
        
        // filter if favorite is on
        if filterItems.selectedSegmentIndex == listType.favorite.hashValue {
            items = items?.filter({ proj -> Bool in
                return proj.isFavorite
            })
        }
        
        // return items
        return items?.filter({ conf -> Bool in
            return conf.yearMonth == yearMonth
        }).count ?? 0
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
        return MemoryDb.shared.headers[section]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showDetail", sender: self)
    }
    
    func getItem(_ index: IndexPath) -> Conference? {
        
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
        
        return items?[index.row]
    }
}

