//
//  playlistTableViewController.swift
//  -> Apple Music
//
//  Created by Meg on 10/19/17.
//  Copyright © 2017 Meg Grasse. All rights reserved.
//

import UIKit

class PlaylistTableViewController: UITableViewController {
    
    let playlistList : SPTPlaylistList
    
    init(playlistList : SPTPlaylistList) {
        self.playlistList = playlistList
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let currentItem = self.navigationController?.navigationBar.topItem
        currentItem?.title = "Spotify Playlists"
        currentItem?.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .done, target: self, action: #selector(dismissWithPlaylists))

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.allowsMultipleSelection = true
    }
    
    // i hate this
    func dismissWithPlaylists() {
        let selectedPaths = self.tableView.indexPathsForSelectedRows
        var selectedPlaylists : [SPTPartialPlaylist] = []
        // idk why my map isn't working
        if let paths = selectedPaths {
            for path in paths {
                selectedPlaylists.append(playlistList.items[path.row] as! SPTPartialPlaylist)
            }
        }
        let VC = self.navigationController?.viewControllers[0]
        if let myVC = VC as? ViewController {
            myVC.createAppleMusicPlaylistsFromSpotify(playlistList: selectedPlaylists)
        }
        self.navigationController?.popViewController(animated: false)
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlistList.items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let playlist = playlistList.items[indexPath.row] as! SPTPartialPlaylist
        cell.textLabel?.text = playlist.name

        return cell
    }

}
