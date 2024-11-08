//
//  RootViewController.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 12/03/24.
//

import UIKit
import MapKit
import Combine

final class RootViewController: UIViewController {
    var childrenContentControllers: [ContentController]
    var currentContentController: ContentController?
    var rootView: RootView { view as! RootView }
    var mapView: MKMapView { rootView.mapView }
    var tabBar: UITabBar { rootView.tabBar }
    var containerView: UIVisualEffectView { rootView.containerView }
    var contentView: UIView { rootView.contentView }
    var refreshButton: RefreshButton { rootView.refreshButton }
    
    private let accessoriesFetcher: AccessoriesFetcher
    private var mapRenderer: MapRenderer?
    private var cancellables: Set<AnyCancellable> = []
    
    init(childrenContentController: [ContentController], accessoriesFetcher: AccessoriesFetcher) {
        self.childrenContentControllers = childrenContentController
        self.accessoriesFetcher = accessoriesFetcher
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = RootView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.delegate = self
        tabBar.items = childrenContentControllers.map(\.tabBarItem)
        tabBar.selectedItem = tabBar.items?.first
        if let contentController = childrenContentControllers.first {
            show(contentController: contentController)
        }
        
        refreshButton.addTarget(self, action: #selector(refresh), for: .touchUpInside)
        accessoriesFetcher.isFetchingAccessories()
            .receive(on: DispatchQueue.main)
            .sink { [refreshButton] isFetching in
                refreshButton.isRefreshing = isFetching
            }
            .store(in: &cancellables)
        
        refresh()
    }
}

extension RootViewController: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if let contentController = childrenContentControllers.first(where: { $0.tabBarItem === item }) {
            show(contentController: contentController)
        }
    }
}

extension RootViewController: ContainerController {
    func show(contentController: ContentController) {
        let previousContentController = currentContentController
        contentController.loadViewIfNeeded()
        contentController.view.translatesAutoresizingMaskIntoConstraints = false
        
        previousContentController?.beginAppearanceTransition(false, animated: true)
        contentController.beginAppearanceTransition(true, animated: true)
        
        previousContentController?.willMove(toParent: nil)
        addChild(contentController)

        previousContentController?.containerController = nil
        contentController.containerController = self

        currentContentController = contentController
        
        mapRendering:
        if let mapRenderer = contentController.mapRenderer() {
            if let oldMapRenderer = self.mapRenderer {
                guard type(of: oldMapRenderer) != type(of: mapRenderer) else { break mapRendering }
            }
            
            mapRenderer.attach(to: mapView)
            self.mapRenderer = mapRenderer
        }
        
        rootView.setContentView(
            contentController.view,
            title: contentController.title,
            headerButtonItems: contentController.toolbarItems,
            preferredContentSize: contentController.preferredContentSize,
            shouldHideTabBar: contentController.hidesBottomBarWhenPushed,
            completion: {
                previousContentController?.endAppearanceTransition()
                contentController.endAppearanceTransition()
                
                previousContentController?.removeFromParent()
                contentController.didMove(toParent: self)
            }
        )
    }
}

private extension RootViewController {
    @objc
    func refresh() {
        accessoriesFetcher.fetchAccessories { result in
            switch result {
            case .success:
                print("Fetched accessories")
            case .failure(let error):
                print("Failed to fetch accessories: \(error)")
            }
        }
    }
}
