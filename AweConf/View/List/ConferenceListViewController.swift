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
import OneSignal

class ConferenceListViewController: BaseViewController {

    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var subscribeButton: UIBarButtonItem!
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

    fileprivate var currentCategory: Category? = nil {
        didSet {
                    
            var data = Array(self.realm.objects(Conference.self).sorted(byKeyPath: "startDate"))

            if let category = currentCategory {
                data = data.filter({ conf -> Bool in
                    return conf.category.contains(category)
                })
            }
            
            conferences = data.filter { conf -> Bool in
                return conf.startDate >= Date()
            }
            
            // set subscribe status
            updateSubscribeStatusUI(isActive: getSubscribeStatus())
        }
    }

    fileprivate var lastUpdate = Date()
    fileprivate var conferences: [Conference]? {
        didSet {
            headers = conferences?.reduce([], { (curr, conf) -> [String] in
                var tmp = curr
                if(!curr.contains(conf.yearMonth)) {
                    tmp.append(conf.yearMonth)
                }
                return tmp
            })
            
            table.reloadData()
        }
    }
    fileprivate var filteredConferences: [Conference]? {
        didSet {
            
            headers = conferences?.reduce([], { (curr, conf) -> [String] in
                var tmp = curr
                if(!curr.contains(conf.yearMonth)) {
                    tmp.append(conf.yearMonth)
                }
                return tmp
            })
            
            table.reloadData()
        }
    }
    fileprivate var categories: [Category]? {
        didSet {
            // contains current category index
            var index = 0
            
            // get index of current category
            if let category = currentCategory {
                // get index of current cat
                index = self.categories?.index(of: category) ?? 0
            }
            
            // move to index
            swipeMenuView.jump(to: index, animated: false)
            swipeMenuView.reloadData(default: index)

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
    fileprivate var headers: [String]? = nil
    
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
        
        // set subscribe button
        subscribeButton.tintColor = .awesomeColor
        
        // set subscribe status
        updateSubscribeStatusUI(isActive: getSubscribeStatus())
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

// MARK: - Subscribe
extension ConferenceListViewController {
    @IBAction func subscribeTrigger() {
        let result = triggerSubscribeStatus()
        updateSubscribeStatusUI(isActive: result)
    }
    
    fileprivate func updateSubscribeStatusUI(isActive: Bool) {
        switch isActive {
        case true:
            subscribeButton.image = #imageLiteral(resourceName: "ic_notifications_active")
        case false:
            subscribeButton.image = #imageLiteral(resourceName: "ic_notifications_off")
        }
    }
    
    fileprivate func getSubscribeStatus() -> Bool {
        guard let cat = currentCategory else { return false }
        return UserDefaults.standard.bool(forKey: "SUBSCRIBE/\(cat.name)")
    }
    
    fileprivate func triggerSubscribeStatus() -> Bool {
        guard let cat = currentCategory else { return false }
        let status = !getSubscribeStatus()
        UserDefaults.standard.set(status, forKey: "SUBSCRIBE/\(cat.name)")
        UserDefaults.standard.synchronize()
        
        // manage onesignal
        if(status) {
            // activate onesignal
            OneSignal.sendTag(cat.name, value: cat.name)
        } else {
            // deactivate onesignal
            OneSignal.deleteTag(cat.name)
        }
        
        return status
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
                // check categories
                self.categories = Array(self.realm.objects(Category.self).sorted(byKeyPath: "name"))

                // sync conferences
                self.getConferences(callback: { conf in
                    
                    // manage current
                    if let current = self.currentCategory {
                        self.currentCategory = nil
                        self.currentCategory = current
                    } else {
                        self.currentCategory = self.categories?[0]
                    }

                    // force refresh
                    self.table.reloadData()

                    // stop refreshing
                    self.refreshControl.endRefreshing()
                })
            }
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
            filteredConferences = conferences?.filter({ conf -> Bool in
                return conf.title.lowercased().contains(searchText.lowercased()) ||
                    conf.address.lowercased().contains(searchText.lowercased())
            })
        }

    }
}

// MARK: - Data source
extension ConferenceListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return headers?.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // get current year month
        guard let yearMonth = headers?[section] else { return 0 }
        
        // get conference items
        let items = isSearchActive ? filteredConferences : conferences
        
        // retrieve conference
        return items?.filter({ conf -> Bool in
            conf.yearMonth == yearMonth
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
        return headers?[section] ?? ""
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showDetail", sender: self)
    }

    func getItem(_ index: IndexPath) -> Conference? {
        // get current year month
        guard let yearMonth = headers?[index.section] else { return nil }
        
        // get conference items
        let items = isSearchActive ? filteredConferences : conferences
        
        // retrieve conference
        return items?.filter({ conf -> Bool in
            conf.yearMonth == yearMonth
        })[index.row]
    }
}

// MARK: - Swipable Menu Delegate
extension ConferenceListViewController: SwipeMenuViewDelegate {
    func swipeMenuView(_ swipeMenuView: SwipeMenuView, didChangeIndexFrom fromIndex: Int, to toIndex: Int) {
        if let categories = categories {
            // set current category
            currentCategory = categories[toIndex]
        }
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
