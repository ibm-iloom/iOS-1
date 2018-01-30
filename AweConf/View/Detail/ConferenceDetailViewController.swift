//
//  ConferenceDetailViewController.swift
//  AweConf
//
//  Created by Matteo Crippa on 30/01/2018.
//  Copyright © 2018 Matteo Crippa. All rights reserved.
//

import UIKit
import MapKit

class ConferenceDetailViewController: BaseViewController {
    @IBOutlet weak var websiteButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var topicsLabel: UILabel!
    
    @IBOutlet weak var topicField: UIStackView!
    @IBOutlet weak var topicSeparator: UIView!
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var mapHeight: NSLayoutConstraint!
    
    var conference: Conference?
    
    private let geoCoder = CLGeocoder()
    
    // card animation handler
    private var cardIsOpen = false {
        didSet {
            // move to thread for smoothness
            DispatchQueue.main.async {
                self.mapHeight.constant = self.cardIsOpen ? 62 : 280
                UIView.animate(withDuration: 0.5, animations: {
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set navigation
        navigationItem.hidesSearchBarWhenScrolling = true
        navigationItem.hidesBackButton = false
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.tintColor = .awesomeColor
        
        // set button tint
        websiteButton.tintColor = .awesomeColor
        favoriteButton.tintColor = .awesomeColor
        
        // add gesture recognizer
        let tapOnMap = UITapGestureRecognizer(target: self, action: #selector(ConferenceDetailViewController.openMap(_:)))
        mapView.addGestureRecognizer(tapOnMap)
        
        // populate UI
        populateUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // update map
        populateMap()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}

// MARK: - Data
extension ConferenceDetailViewController {
    fileprivate func populateUI() {
        guard let conference = conference else { return }
        
        // set buttons
        websiteButton.setTitle(conference.homepage, for: .normal)
        
        // set labels
        titleLabel.text = conference.title
        startDateLabel.text = conference.startDate.toString(dateFormat: "dd")
        endDateLabel.text = conference.endDate.toString(dateFormat: "dd")
        countryLabel.text = conference.country
        cityLabel.text = conference.city
        
        // tweak view according topic content exists
    
        if conference.topic.count > 0 {
            topicField.isHidden = false
            let content = conference.topic.reduce("", { (result, topic) -> String in
                return result + "\(topic),"
            })
            topicsLabel.text = String(content.dropLast())
        } else {
            topicField.isHidden = true
        }
        
        // manage topic separator according topic stack visibility
        topicSeparator.isHidden = topicField.isHidden
        
        // set current favorite status
        updateFavoriteUI()
    }
    
    fileprivate func updateFavoriteUI() {
        guard let conference = conference else { return }
        favoriteButton.isSelected = conference.isFavorite
    }
    
    fileprivate func populateMap() {
        guard let conference = conference else { return }
        getLocationFrom(address: conference.address)
    }
}

// MARK: - Action
extension ConferenceDetailViewController {
    
    @IBAction func tapFavorite() {
        if var conference = conference {
            conference.isFavorite = !conference.isFavorite
        }
        // update UI
        updateFavoriteUI()
    }
    
    @IBAction func openLink() {
        guard let conference = conference, let url = URL(string: conference.homepage) else { return }
        UIApplication.shared.open(url)
    }
    
    @objc func openMap(_ sender: UITapGestureRecognizer) {
        guard
            let conference = conference,
            let encodedAddress = conference.address.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
            let url = URL(string: "http://maps.apple.com/maps?saddr=\(encodedAddress)")
            else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Map
extension ConferenceDetailViewController: MKMapViewDelegate {
    
    fileprivate func getLocationFrom(address: String) {
        geoCoder.geocodeAddressString(address) { (placemarks, _) in
            guard
                let placemarks = placemarks,
                let location = placemarks.first?.location
                else { return }
            
            // center map
            self.centerMapOnLocation(location: location)
            
            // add annotation
            self.addAnnotationToMapAt(location: location)
            
        }
    }
    
    fileprivate func addAnnotationToMapAt(location: CLLocation) {
        
        // create marker
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        
        // add marker
        mapView.addAnnotation(annotation)
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let regionRadius: CLLocationDistance = 400
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseIdentifier = "pin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? MKMarkerAnnotationView
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView?.canShowCallout = false
            annotationView?.markerTintColor = .awesomeColor
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
}

// MARK: - Swipe gesture
extension ConferenceDetailViewController {
    
    @IBAction func swipeGesture(recognizer: UISwipeGestureRecognizer) {
        switch recognizer.direction {
        case UISwipeGestureRecognizerDirection.up:
            cardIsOpen = true
        case UISwipeGestureRecognizerDirection.down:
            cardIsOpen = false
        default:
            break
        }
    }
    
}
