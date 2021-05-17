//
//  TwitterAPI.swift
//  Elonis
//
//  Created by Ondrej Winter on 15.03.2021.
//
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import UIKit

class TwitterAPI {
    
    struct Auth {
        static var apiKey = "LE3z1eKpvJkIKu6dJR0ThLLPB"
        static var apiSecretKey = "HJ3CHHqooLOcCEjfgLKw70pEIVdXC0JQBQwpEsk6ylYb97dK6c"
        static var bearer = "Bearer AAAAAAAAAAAAAAAAAAAAAPCbNgEAAAAA1JO5dkebDHIX6F%2Be0PiT%2FqssDkE%3DOmLP8dUNKQ115dqAnznlmx5VeDUi4oXJ70GKBm3yYJu5vwS3Ag"
    }
    
    enum Endpoints {
        static let base = "https://api.twitter.com/2"
        
        case getUserIdByUsername(String)
        case getRecentTweets(Int, String)
        case getAProfilePicture(String)
        
        var stringValue: String {
            switch self {
            case .getUserIdByUsername(let username):
                return Endpoints.base + "/users/by/username/\(username)" + "?user.fields=created_at" + ",profile_image_url"
            case .getRecentTweets(let numberOfRecentTweets, let userId):
                return Endpoints.base + "/users/" + userId + "/tweets?max_results=\(numberOfRecentTweets)" + "&tweet.fields=created_at"
            case .getAProfilePicture(let id):
            return Endpoints.base + "/users/" + id
            }
        }
        
        // found nil while unwrapping an optional value
        var url: URL {
            return URL(string: stringValue)!
        }
        
    }
    
    
    
    /*
    class func getAProfilePicture(id: String) {
        var request = URLRequest(url: Endpoints.getAProfilePicture(id).url, timeoutInterval: Double.infinity)
        request.addValue(Auth.bearer, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        taskForGetRequest(request: request, responseType: <#T##Decodable.Protocol#>, rangeFrom: 0) { <#Decodable?#>, <#Error?#> in
            
        }
        
    }
 
 */


    class func getUserIdByUsername(username:String, completion: @escaping(UserIdData?, Error?) -> Void) {

        var request = URLRequest(url: Endpoints.getUserIdByUsername(username).url,timeoutInterval: Double.infinity)
        request.addValue(Auth.bearer, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"

        taskForGetRequest(request: request, responseType: GetUserIdResponse.self, rangeFrom: 0) { (jsonObject, error) in
            if let jsonObject = jsonObject {
                print("jsonObject is: \(jsonObject)")
                completion(jsonObject.data,nil)
            } else {
                print("error is: \(error)")
                completion(nil,error)
            }
        }
    }
    
    class func getRecentTweets(numberOfRecentTweets: Int, userId: String, completion: @escaping([GetTweetResponse], Error?) -> Void) {

        var request = URLRequest(url: Endpoints.getRecentTweets(numberOfRecentTweets, userId).url,timeoutInterval: Double.infinity)
        request.addValue(Auth.bearer, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"

        taskForGetRequest(request: request, responseType: GetTweetResponse.self, rangeFrom: 0) { (jsonObject, error) in
            if let jsonObject = jsonObject {
                completion([jsonObject], nil)
            } else {
                completion([], error)
            }
        }

        
        
    }
    
    
    
    
    
    class func taskForGetRequest<ResponseType: Decodable> (request: URLRequest, responseType: ResponseType.Type, rangeFrom: Int, completion: @escaping(ResponseType?, Error?)->Void) {
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil,error)
                }
                return
            }
            print(response)
            print(data)
            let string = String(data: data, encoding: .utf8)
            print(string)
            do {
                let range = rangeFrom..<data.count
                let newData = data.subdata(in: range)
                let jsonObject = try JSONDecoder().decode(ResponseType.self, from: newData)
                DispatchQueue.main.async {
                    completion(jsonObject, nil)
                }
            } catch {
                print("error from taskForGetRequest is: \(error)")
                completion(nil, error)
            }
            
        }
        task.resume()
    }
    


}
