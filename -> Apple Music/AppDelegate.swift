//
//  AppDelegate.swift
//  -> Apple Music
//
//  Created by Meg Grasse on 1/15/17.
//  Copyright © 2017 Meg Grasse. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var auth: SPTAuth?
    var VC: ViewController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //Init spotify info
        self.auth = SPTAuth.defaultInstance()
        self.auth?.clientID = kClientID
        self.auth?.redirectURL = NSURL(string: kCallbackURL) as URL!
        self.auth?.sessionUserDefaultsKey = kSessionUserDefaultsKey
        self.auth?.requestedScopes = [SPTAuthPlaylistReadPrivateScope, SPTAuthPlaylistReadCollaborativeScope, SPTAuthUserLibraryReadScope]
        
        //Init VC
        self.VC = ViewController.init(nibName: nil, bundle: nil)
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = self.VC
        self.window?.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()
        
        DispatchQueue.main.async {
            if (self.auth?.session != nil && (self.auth?.session.isValid())!) {
                self.getPlaylists()
            } else {
                //only works if app is installed
                if (SPTAuth.supportsApplicationAuthentication()) {
                    UIApplication.shared.open((self.auth?.spotifyAppAuthenticationURL())!, options: [:], completionHandler: {(present) in
                        if (self.auth?.session != nil && (self.auth?.session.isValid())!) {
                        }
                    })
                }
            }
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // Handle auth callback
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if (self.auth?.canHandle(url))! {
            self.auth?.handleAuthCallback(withTriggeredAuthURL: url, callback: { (error, session) in
                if (error != nil) {
                    print(error!)
                }
                if (session != nil) {
                    self.getPlaylists()
                }
            })
        return true
        }
    return false
    }
    
    func getPlaylists() {
        SPTPlaylistList.playlists(forUser: auth?.session.canonicalUsername, withAccessToken: auth?.session.accessToken, callback: {(error, playlistlist) in
            if (error != nil) {
                print (error!)
            }
            
            self.VC?.createAppleMusicPlaylistsFromSpotify(playlistList: playlistlist as! SPTPlaylistList)
        })
    }

}

