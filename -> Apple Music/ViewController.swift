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
    let errorLog = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MPMediaLibrary.requestAuthorization { (authStatus) in
            if (authStatus != .authorized) {
                print("Need authorization")
            }
        }

        UIView.animate(withDuration: 0.1, delay: 0.0, options: [UIViewAnimationOptions.repeat], animations: {
            self.view.backgroundColor = UIColor(red:0.78, green:0.27, blue:0.99, alpha:1.0)
            self.view.backgroundColor = UIColor(red:0.35, green:0.34, blue:0.84, alpha:1.0)
        }, completion: nil)
        
        errorLog.frame.size = CGSize(width: self.view.bounds.size.width * 3/4, height: self.view.bounds.size.height * 3/4)
        errorLog.center = self.view.center
        errorLog.numberOfLines = 0
        errorLog.textAlignment = .center
        errorLog.lineBreakMode = .byWordWrapping
        errorLog.textColor = UIColor.white
        errorLog.font = UIFont.boldSystemFont(ofSize: 16)
        errorLog.text = "Apple Music couldn't find the following tracks:"
        self.view.addSubview(errorLog)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createAppleMusicPlaylistsFromSpotify(playlistList: SPTPlaylistList) {
        for spotifyPlaylist in playlistList.items {
                self.initAppleMusicPlaylists(playlist: spotifyPlaylist as! SPTPartialPlaylist, completionHandler: {(appleMusicPlaylist, snapshot) in
                    for spotifyTrack in (snapshot?.firstTrackPage.items)! {
                        if let spotifyTrack = spotifyTrack as? SPTPlaylistTrack {
                            self.trackForTrack(spotifyTrack: spotifyTrack, completionHandler: {(appleMusicId) in
                                appleMusicPlaylist?.addItem(withProductID: appleMusicId!, completionHandler: {(error) in
                                    if (error != nil) {
                                        print(error!)
                                    } else {
    //                                    print("Successfully added " + appleMusicId! + " to playlist " + (playlist?.name)!)
                                    }
                                })
                            })
                        }
                    }
                })
        }
    }
    
    func initAppleMusicPlaylists(playlist: SPTPartialPlaylist, completionHandler: @escaping (MPMediaPlaylist? ,SPTPlaylistSnapshot?) -> Void) {
        SPTPlaylistSnapshot.playlist(withURI: playlist.uri, accessToken: auth?.session.accessToken, callback: { (error, snapshot) in
            if (error != nil) {
                print(error!)
            }
            if let snapshot = snapshot as? SPTPlaylistSnapshot {
                let playlistData = MPMediaPlaylistCreationMetadata.init(name: (snapshot.name)!)
                // if getPlaylist(with:creationMetadata:completionHandler:) can't find a playlist with the given UUID, it creates a new one
                MPMediaLibrary.default().getPlaylist(with: UUID(), creationMetadata: playlistData, completionHandler: {(playlist, error) in
                    if (error != nil) {
                        print(error!)
                    } else {
//                        print("Successfully initialized playlist " + (playlist?.name)!)
                    }
                    completionHandler(playlist, snapshot)
                })
            }
        })
    }
    
    func trackForTrack(spotifyTrack: SPTPlaylistTrack, completionHandler: @escaping (String?) -> Void) {
        let URL = makeRequestURL(track: spotifyTrack)
        if (URL != nil) {
            let request = URLRequest.init(url: URL! as URL)
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
                            } else {
                                let artists = spotifyTrack.artists.map { ($0 as! SPTPartialArtist).name }.joined(separator: " & ")
                                self.errorLog.text = self.errorLog.text! + "\n\n" + spotifyTrack.name + " by " + artists
                                print("Couldn't find " + spotifyTrack.name + " by " + artists + " on Apple Music")
                                print(URL?.absoluteString! as Any)
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
    
    func makeRequestURL(track: SPTPlaylistTrack) -> NSURL? {
        // bleh, compiler can't tell these are all arrays unless stored as local vars
        let trackTerms = track.name.components(separatedBy: " ")
        let artistTerms = track.artists.map { ($0 as! SPTPartialArtist).name.components(separatedBy: " ") }.joined()
        let albumTerms = track.album.name.components(separatedBy: " ")
        let queryTerms = trackTerms + artistTerms + albumTerms
        let explicit = track.flaggedExplicit ? "Yes" : "No"
        
        // Can I make a dictionary with the different attributes?
        let urlString = "https://itunes.apple.com/search?term=" + queryTerms.joined(separator: "+") + "&media=music&entity=song&explicit=" + explicit + "&limit=1"
        let url = NSURL(string: urlString)
        if (url != nil) {
            return url
        } else {
            print(urlString)
            return nil
        }
    }
}


