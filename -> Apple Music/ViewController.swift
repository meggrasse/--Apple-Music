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
    let serialQueue = DispatchQueue(label: "iTunesRequests")
    
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
                // if getPlaylist(with:creationMetadata:completionHandler:) can't find a playlist with the given UUID, it creates a new one
                MPMediaLibrary.default().getPlaylist(with: UUID(), creationMetadata: playlistData, completionHandler: {(playlist, error) in
                    if (error != nil) {
                        print(error!)
                    } else {
                        print("Successfully initialized playlist " + (playlist?.name)!)
                    }

                    for spotifyTrack in (snapshot?.firstTrackPage.items)! {
                        if let spotifyTrack = spotifyTrack as? SPTPlaylistTrack {
                            self.findAppleMusicTrackIdForSpotifyTrack(track: spotifyTrack, completionHandler: {(appleMusicId) in
                                playlist?.addItem(withProductID: appleMusicId!, completionHandler: {(error) in
                                    if (error != nil) {
                                        print(error!)
                                    } else {
                                        print("Successfully added " + appleMusicId! + " to playlist " + (playlist?.name)!)
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

    func findAppleMusicTrackIdForSpotifyTrack(track: SPTPlaylistTrack, completionHandler: @escaping (String?) -> Void) {
        // bleh, compiler can't tell these are all arrays unless stored as local vars
        let trackTerms = track.name.components(separatedBy: " ")
        let artistTerms = track.artists.map { ($0 as! SPTPartialArtist).name.components(separatedBy: " ") }.joined()
        let albumTerms = track.album.name.components(separatedBy: " ")
        let queryTerms = trackTerms + artistTerms + albumTerms
        let explicit = track.flaggedExplicit ? "Yes" : "No"

        // Can I make a dictionary with the different attributes?
        let urlString = "https://itunes.apple.com/search?term=" + queryTerms.joined(separator: "+") + "&media=music&entity=song&explicit=" + explicit + "&limit=1"
        print(urlString)
        let url = NSURL(string: urlString)
        if (url != nil) {
            let request = URLRequest.init(url: url! as URL)
            // using a shared session ensures we aren't creating a new session for each request
            let session = URLSession.shared
            
            let task = session.dataTask(with: request, completionHandler: {(data, response, error) in
                if (error != nil) {
                    print(error!)
                }
                do {
                    if let data = data as Data! {
                        var json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
                        if let results = json["results"] as? [[String:AnyObject]] {
                            if (results.count > 0) {
                                if let trackId = results[0]["trackId"] as? NSNumber {
                                    completionHandler(trackId.stringValue)
                                }
                            }
                        }
                    } else {
                        print(data as Any)
                    }
                }
                catch {
                    if let httpResponse = response as? HTTPURLResponse {
                        print(httpResponse.statusCode)
                    } else {
                        print(response as Any)
                    }
                }
            
            })
            // I need to send max 20 req/min
            // I really want to use asyncAfter(wallDeadline...) for this
            self.serialQueue.sync {
                DispatchQueue.main.async {
                    sleep(3)
                    task.resume()
                }
            }
        }
    }
}


