//
//  SceneDelegate.swift
//  Elonis
//
//  Created by Ondrej Winter on 15.03.2021.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    let dataController = DataController()


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        let tabBarController = window?.rootViewController as! UITabBarController
        let navigationController = tabBarController.viewControllers![0] as! UINavigationController
        let latestTweetsController = navigationController.topViewController as! LatestTweetsController
        latestTweetsController.dataController = dataController
        let secondNavController = tabBarController.viewControllers![1] as! UINavigationController
        let addFilterController = secondNavController.topViewController as! ActiveFiltersController
        addFilterController.dataController = dataController
    }

}

