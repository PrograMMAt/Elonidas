//
//  DataController.swift
//  Elonidas
//
//  Created by Ondrej Winter on 24.03.2021.
//

import Foundation
import UIKit
import Firebase

class DataController {
    var ref: DatabaseReference {
        return Database.database().reference()
    }
    
    var filteredUsernames: [DataSnapshot] = []
    var tweetsArray: [TweetDictionary] = []
}
