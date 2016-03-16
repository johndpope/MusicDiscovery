//
//  MusicPlayer.swift
//  MusicDiscovery
//
//  Created by Nick Martinson on 4/14/15.
//  Copyright (c) 2015 Nick Martinson. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

class PlayListController:UIViewController, UITableViewDataSource, UITableViewDelegate
{
    @IBOutlet weak var playlistTableView: UITableView!
    var session:SPTSession!
    let baseURL = NSURL(string: "https://api.spotify.com/v1/me")!
    var userURL = NSURL(string: "https://api.spotify.com/v1/users/1228889752/playlists")
    var playlists:SPTPlaylistList = SPTPlaylistList()
    var playlistCount = 0
    var selectedCellIndex = 0
    let backgroundImage = UIImageView(image: UIImage(named: "audiowave2"))
    
    override func viewDidLoad()
    {
        backgroundImage.contentMode = .ScaleAspectFill
        backgroundImage.alpha = 0.5
        playlistTableView.backgroundView = backgroundImage


        
        // gets a hold of the session object
        if let sessionObj:AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("SpotifySession")
        {
            // convert the stored session object back to SPTSession
            let sessionData = sessionObj as! NSData
            session = NSKeyedUnarchiver.unarchiveObjectWithData(sessionData) as! SPTSession
            
        }
        
        // Request a list of the user's playlists
        SPTRequest.playlistsForUserInSession(session, callback: { (error, playlists) -> Void in
            if error != nil
            {
                print("Playlist request error")
            }
            else
            {
                // make sure there are items in the playlist
                if let playlistsItems = (playlists as! SPTPlaylistList).items
                {
                    self.playlists = (playlists as? SPTPlaylistList)!
                    self.playlistCount = playlistsItems.count
                    self.playlistTableView.reloadData()
                }
            }
        })
        
    }
    
    /******************************************************************************************************
    *
    ******************************************************************************************************/
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        // Pass the playlist URI to the next view controller so it can request the songs
        if segue.identifier == "playlistSongSegue"
        {
            let controller = segue.destinationViewController as! PlaylistSongController
            controller.playlistURI = playlists.items[selectedCellIndex].playableUri()
            controller.playlistName = playlists.items[selectedCellIndex].name
        }
    }
    
    /******************************************************************************************************
    *   Stores the index of the selected cell so that the playlist array can be referenced at that index
    *   for passing the URI to the next view.
    ******************************************************************************************************/
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        selectedCellIndex = indexPath.row
        performSegueWithIdentifier("playlistSongSegue", sender: self)
    }
    
    /******************************************************************************************************
    *   Puts the playlist name in the cell
    ******************************************************************************************************/
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("playlistCell")! as UITableViewCell
        cell.textLabel?.text = playlists.items[indexPath.row].name
        cell.textLabel?.textColor = UIColor.whiteColor()
        return cell
    }
    
    /******************************************************************************************************
    *
    ******************************************************************************************************/
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return playlistCount
    }
    
    /******************************************************************************************************
    *   Tells the tableview it only has 1 section
    ******************************************************************************************************/
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
}