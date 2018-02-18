//
//  UserCollectionViewCell.swift
//  AweConf
//
//  Created by Matteo Crippa on 18/02/2018.
//  Copyright © 2018 Matteo Crippa. All rights reserved.
//

import UIKit
import Kingfisher

class UserCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var userImage: UIImageView!
    
    var imageUrl: String? = nil
    
    func setup(imageUrl: String) {
        self.imageUrl = imageUrl
        
        guard let url = URL(string: "https://avatars.io/twitter/" + imageUrl) else { return }
        userImage.kf.setImage(with: url)
    }
}
