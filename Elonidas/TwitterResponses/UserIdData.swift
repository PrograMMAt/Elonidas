//
//  Rdata.swift
//  Elonis
//
//  Created by Ondrej Winter on 16.03.2021.
//

import Foundation
import UIKit

struct UserIdData: Codable {
    
    let username: String
    let name: String
    let id: String
    let createdAt: String
    let profileImageUrlString: String
    
    private enum CodingKeys: String, CodingKey {
        case username
        case name
        case id
        case createdAt = "created_at"
        case profileImageUrlString = "profile_image_url"
    }
    
}
