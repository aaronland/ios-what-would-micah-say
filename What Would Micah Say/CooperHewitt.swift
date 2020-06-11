//
//  CooperHewitt.swift
//  shoebox
//
//  Created by asc on 6/11/20.
//  Copyright © 2020 Aaronland. All rights reserved.
//

import Foundation

/*
 {"micah":{"says":"Next thing you know I'm thinking about a completely different piece of the puzzle!"},"stat":"ok","event_publishing_state":"ok"}
 
 */

struct WWMSResponse: Codable {
    var micah: WWMS
    var stat: String
}

struct WWMS: Codable {
    var says: String
}

class CooperHewittAPI {
    
    public let auth_url = "https://collection.cooperhewitt.org/api/oauth2/authenticate/"
    public let token_url = "https://collection.cooperhewitt.org/api/oauth2/access_token/"
    
    var endpoint = "https://api.collection.cooperhewitt.org/rest/"
    var access_token: String?
    
    init(access_token: String) {
        self.access_token = access_token
    }
    
    init(endpoint: String, access_token: String) {
        self.endpoint = endpoint
        self.access_token = access_token
    }
    
    public func ExecuteMethod(method: String, params: [String:String], completion: @escaping (Result<Data, Error>)->()) {
        
        let url = URL(string: self.endpoint)!
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!

        components.queryItems = [
            URLQueryItem(name: "method", value: method),
            URLQueryItem(name: "access_token", value: self.access_token),
        ]

        for (k, v) in params {
            components.queryItems?.append(URLQueryItem(name: k, value: v))
        }
        
        let query = components.url!.query
        
        let session = URLSession.shared
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.httpBody = Data(query!.utf8)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in

            if error != nil {
                completion(.failure(error!))
                return
            }

            //let rsp = String(decoding: data!, as: UTF8.self)
            //print("OKAY", rsp)
            
            completion(.success(data!))
        })
        task.resume()
    }
}
