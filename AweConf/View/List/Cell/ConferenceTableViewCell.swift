//
//  ConferenceTableViewCell.swift
//  AweConf
//
//  Created by Matteo Crippa on 30/01/2018.
//  Copyright © 2018 Matteo Crippa. All rights reserved.
//

import UIKit
import Exteptional

class ConferenceTableViewCell: UITableViewCell {
    
    @IBOutlet weak var conferenceFlag: UILabel!
    @IBOutlet weak var conferenceTitle: UILabel!
    @IBOutlet weak var conferenceDate: UILabel!
    @IBOutlet weak var conferenceFavorite: UIButton!
    @IBOutlet weak var conferenceIsNew: UILabel!
    
    private var conference: Conference?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func setup(with conference: Conference) {
        self.conference = conference
        conferenceFlag.text = conference.emojiflag
        conferenceTitle.text = conference.title
        
        if conference.enddate != conference.startdate {
            conferenceDate.text = (conference.start?.toString(dateFormat: "dd") ?? "") + " - " + (conference.end?.toString(dateFormat: "dd") ?? "")
        } else {
            conferenceDate.text = conference.start?.toString(dateFormat: "dd") ?? ""
        }
        conferenceFavorite.tintColor = .awesomeColor
        
        conferenceIsNew.textColor = .awesomeColor
        
        conferenceIsNew.isHidden = !conference.isNew
        
        updateButtonUI()
    }
    
    @IBAction func triggerFavorite() {
        guard let conference = conference else { return }
        self.conference?.isFavorite = !conference.isFavorite
        updateButtonUI()
    }
    
    private func updateButtonUI() {
        guard let conference = conference else { return }
        conferenceFavorite.isSelected = conference.isFavorite
    }
}
