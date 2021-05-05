//
//  Tweet.swift
//  Elonis
//
//  Created by Ondrej Winter on 16.03.2021.
//

import Foundation

struct Tweet: Codable {
    let createdAt: String
    let id: String
    let text: String
    
    var dictionary: [String: Any] {
        return [
            "createdAt": createdAt,
            "id": id,
            "text": text
        ]
    }
    
    var nsDictionary: NSDictionary {
        return dictionary as NSDictionary
    }
    
    private enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case id
        case text
    }
}
