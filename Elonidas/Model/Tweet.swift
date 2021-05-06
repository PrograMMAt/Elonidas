//
//  Tweet.swift
//  Elonidas
//
//  Created by Ondrej Winter on 06.05.2021.
//

import UIKit
import Foundation



struct Tweet {
    let username = "username"
    let tweetId = "tweetId"
    let text = "text"
    let createdAt = "createdAt"
    
    
    init(username: String, tweetId: String, text: String, createdAt: String) {
        self.username = username
        self.tweetId = tweetId
        self.text = text
        self.createdAt = createdAt
    }
}
