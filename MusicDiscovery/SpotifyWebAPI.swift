//
//  SpotifyWebAPI.swift
//  MusicDiscovery
//
//  Created by Nick Martinson on 4/14/15.
//  Copyright (c) 2015 Nick Martinson. All rights reserved.
//

import Foundation
import Alamofire

class SpotifyWebAPI
{
    let meURL = NSURL(string: "https://api.spotify.com/v1/me")!
    let userURL = "https://api.spotify.com/v1/users"
    
    func getMeInfo(session: SPTSession)
    {
        let mutableRequest = NSMutableURLRequest(URL: meURL)
        mutableRequest.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        mutableRequest.setValue("Accept", forHTTPHeaderField: "application/json")
        let request = Alamofire.request(mutableRequest)
        
        request.responseJSON { request, response, result in
            switch result {
            case .Success(let JSON):
                print("Success with JSON: \(JSON)")
               // let json = JSON(response)
                let userID = JSON["id"]
                
            case .Failure(let data, let error):
                print("Request failed with error: \(error)")
                
                if let data = data {
                    print("Response data: \(NSString(data: data, encoding: NSUTF8StringEncoding)!)")
                }
            }
        }
        

    }
    
    func getMyPlaylists(session:SPTSession, userID: String)
    {
        
        let URL = NSURL(string: "\(userURL)/\(userID)/playlists")
        let mutableRequest = NSMutableURLRequest(URL: URL!)
        mutableRequest.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        mutableRequest.setValue("Accept", forHTTPHeaderField: "application/json")
        let request = Alamofire.request(mutableRequest)
        
        request.responseJSON { request, response, result in
            switch result {
            case .Success(let JSON):
                print("Success with JSON: \(JSON)")
//                let json = JSON as! Dictionary
//                
//                let count = json["total"].intValue
//                for(var i = 0; i < count; i++)
//                {
//                    println(json["items"][i]["name"].stringValue)
//                }
                
            case .Failure(let data, let error):
                print("Request failed with error: \(error)")
                
                if let data = data {
                    print("Response data: \(NSString(data: data, encoding: NSUTF8StringEncoding)!)")
                }
            }
        }
        

    }
    
    
}