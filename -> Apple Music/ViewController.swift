//
//  ViewController.swift
//  -> Apple Music
//
//  Created by Meg Grasse on 1/15/17.
//  Copyright © 2017 Meg Grasse. All rights reserved.
//

import UIKit
import MediaPlayer

class ViewController: UIViewController {
    
    var auth = (UIApplication.shared.delegate as! AppDelegate).auth
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MPMediaLibrary.requestAuthorization { (authStatus) in
            if (authStatus != .authorized) {
                print("Need authorization")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createAppleMusicPlaylistForSpotifyPlaylistList(playlistList: SPTPlaylistList) {
        for playlist in playlistList.items {
            snapshotForPlaylist(playlist: playlist as! SPTPartialPlaylist, completionHandler: {(snapshot) in
                let playlistData = MPMediaPlaylistCreationMetadata.init(name: (snapshot?.name)!)
                MPMediaLibrary.default().getPlaylist(with: UUID(), creationMetadata: playlistData, completionHandler: {(playlist, error) in
                    if (error != nil) {
                        print(error!)
                    }

                    for spotifyTrack in (snapshot?.firstTrackPage.items)! {
                        if let spotifyTrack = spotifyTrack as? SPTPlaylistTrack {
                            findAppleMusicTrackIdForSpotifyTrack(track: spotifyTrack, completitionHandler: {(appleMusicId) in
                                playlist?.addItem(withProductID: appleMusicId!, completionHandler: {(error) in
                                    if (error != nil) {
                                        print(error!)
                                    }
                                    
                                })
                            })
                        }
                    }
                })
            })
        }
    }
    
    func snapshotForPlaylist(playlist: SPTPartialPlaylist, completionHandler: @escaping (SPTPlaylistSnapshot?) -> Void) {
            SPTPlaylistSnapshot.playlist(withURI: playlist.uri, accessToken: auth?.session.accessToken, callback: { (error, snapshot) in
                if (error != nil) {
                    print(error!)
                }
                
                if let snapshot = snapshot as? SPTPlaylistSnapshot {
                    completionHandler(snapshot)
                }
            })
        }
    }

    func findAppleMusicTrackIdForSpotifyTrack(track: SPTPlaylistTrack, completitionHandler: @escaping (String?) -> Void) {
        var queryTerms = track.name.components(separatedBy: " ") //Add more later
        var parameters = ""
        
        for i in 0...(queryTerms.count - 1) {
            var queryTerm = queryTerms[i]
            if (i != 0) {
                queryTerm = "+" + queryTerm
            }
            
            parameters += queryTerm
        }
        
        let urlString = "https://itunes.apple.com/search?term=" + parameters + "&limit=1"
        let url = NSURL(string: urlString)
        if (url != nil) {
            let request = URLRequest.init(url: url as! URL)
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            
            let task = session.dataTask(with: request, completionHandler: {(data, response, error) in
                if (error != nil) {
                    print(error!)
                } else {
                //should check status code here
                    do {
                        var json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
                        if let results = json["results"] as? [[String:AnyObject]] {
                            if (results.count > 0) {
                                if let trackId = results[0]["trackId"] as? NSNumber {
                                    completitionHandler(trackId.stringValue)
                                }
                            }
                        }
                    }
                    catch {
                        print ("Error")
                    }
                }
            })
            
            task.resume()
        }
    }


