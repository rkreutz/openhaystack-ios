//
//  SceneDelegate.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 12/03/24.
//

import UIKit
import Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard
            let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let scene = (scene as? UIWindowScene)
        else { return }
        
        window = UIWindow(windowScene: scene)
        window?.rootViewController = RootViewController(
            childrenContentController: [
                AccessoriesViewController(
                    accessoriesProvider: appDelegate.accessoriesManager,
                    accessoryModifier: appDelegate.accessoriesManager,
                    accessoryCreator: appDelegate.accessoriesManager, 
                    accessoriesImporter: appDelegate.accessoriesManager
                ),
                SettingsViewController()
            ],
            accessoriesFetcher: appDelegate.accessoriesManager
        )
        
        window?.makeKeyAndVisible()
    }
}

