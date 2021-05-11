//
//  NewTweet.swift
//  Elonidas
//
//  Created by Ondrej Winter on 07.05.2021.
//

import UIKit
import Foundation



class NewTweet {
    let username: String
    let tweetId: Int
    let text: String
    let createdAt: String
    
    
    init(username: String, tweetId: Int, text: String, createdAt: String) {
        self.username = username
        self.tweetId = tweetId
        self.text = text
        self.createdAt = createdAt
    }

}
