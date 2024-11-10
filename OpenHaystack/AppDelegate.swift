//
//  AppDelegate.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 12/03/24.
//

import UIKit
import CoreLocation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    let accessoriesManager = AccessoriesManager(
        repository: AccessoriesRepository(
            storage: UserDefaults.standard,
            protectedStorage: KeychainStorage(),
            httpClient: URLSessionHTTPClient(session: .shared),
            serverConfigurationRepository: ServerConfigurationRepository(storage: UserDefaults.standard), 
            reportsConfigurationRepository: ReportsConfigurationRepository(storage: UserDefaults.standard), 
            geocodeRepository: GeocodeRepository()
        ),
        scanner: .init()
    )
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
