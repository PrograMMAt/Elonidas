//
//  Tweet.swift
//  Elonidas
//
//  Created by Ondrej Winter on 06.05.2021.
//

import UIKit
import Foundation



class TweetDictionary {
    let username: String
    let tweetId: String
    let text: String
    let createdAt: String
    
    
    init(username: String, tweetId: String, text: String, createdAt: String) {
        self.username = username
        self.tweetId = tweetId
        self.text = text
        self.createdAt = createdAt
    }

}
