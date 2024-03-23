//
//  RootView.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 13/03/24.
//

import UIKit
import MapKit

final class RootView: UIView {
    let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.insetsLayoutMarginsFromSafeArea = false
        return mapView
    }()
    
    let containerView: UIVisualEffectView = {
        let containerView = UIVisualEffectView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.effect = UIBlurEffect(style: .systemThinMaterial)
        containerView.layer.cornerRadius = Constants.cornerRadius
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.clipsToBounds = true
        return containerView
    }()
    
    let tabBar: UITabBar = {
        let tabBar = UITabBar()
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        tabBar.isTranslucent = true
        tabBar.setContentHuggingPriority(.required, for: .vertical)
        tabBar.setContentCompressionResistancePriority(.required, for: .vertical)
        let barAppearance = UIBarAppearance()
        barAppearance.configureWithTransparentBackground()
        barAppearance.shadowColor = UIColor.separator
        tabBar.standardAppearance = UITabBarAppearance(barAppearance: barAppearance)
        tabBar.scrollEdgeAppearance = UITabBarAppearance(barAppearance: barAppearance)
        tabBar.selectedItem = tabBar.items?.first
        return tabBar
    }()
    
    let contentView: UIView = {
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.clipsToBounds = true
        return contentView
    }()
    
    let headerView: HeaderView = {
        let headerView = HeaderView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        return headerView
    }()
    
    let refreshButton: RefreshButton = {
        let button = RefreshButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .systemFill
        return button
    }()
    
    private var hasSetup: Bool = false
    private var containerViewOriginalOffset: CGFloat = 0
    private var containerViewTopConstraint: NSLayoutConstraint?
    private var containerViewMinHeightConstraint: NSLayoutConstraint?
    private var tabBarBottomConstraint: NSLayoutConstraint?
    
    init() {
        super.init(frame: .zero)
        addSubview(mapView)
        addSubview(refreshButton)
        addSubview(containerView)
        addSubview(contentView)
        addSubview(headerView)
        addSubview(tabBar)
        
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard
            window != nil,
            !hasSetup
        else { return }
        hasSetup = true
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: topAnchor),
            mapView.bottomAnchor.constraint(equalTo: bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        NSLayoutConstraint.activate([
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: safeAreaLayoutGuide.topAnchor, multiplier: 1)
        ])
        
        tabBarBottomConstraint = tabBar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        NSLayoutConstraint.activate([
            tabBarBottomConstraint.unsafelyUnwrapped,
            tabBar.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor)
        ])
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            contentView.bottomAnchor.constraint(equalTo: tabBar.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        NSLayoutConstraint.activate([
            refreshButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            refreshButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
        
        headerView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGestureResponder)))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        mapView.layoutMargins = .init(top: 0, left: 0, bottom: containerView.bounds.height, right: 0)
    }
    
    func setContentView(
        _ view: UIView,
        title: String?,
        headerButtonItems: [UIBarButtonItem]?,
        preferredContentSize: CGSize,
        shouldHideTabBar: Bool,
        completion: @escaping () -> Void
    ) {
        headerView.title = title
        headerView.barButtonItems = headerButtonItems
        layoutIfNeeded()

        contentView.subviews.forEach { $0.removeFromSuperview() }
        contentView.addSubview(view)
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            view.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            view.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 1)
        ])
        
        if preferredContentSize.width.isFinite,
           preferredContentSize.height.isFinite {
            NSLayoutConstraint.activate([
                {
                    let constraint = view.widthAnchor.constraint(equalToConstant: preferredContentSize.width)
                    constraint.priority = .defaultHigh
                    return constraint
                }(),
                {
                    let constraint = view.heightAnchor.constraint(equalToConstant: preferredContentSize.height)
                    constraint.priority = .defaultHigh
                    return constraint
                }(),
            ])
        } else {
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
            ])
        }
        
        tabBarBottomConstraint?.constant = shouldHideTabBar ? tabBar.bounds.height + safeAreaInsets.bottom : 0
        
        UIView.animate(
            withDuration: Constants.animationDuration,
            animations: {
                self.tabBar.alpha = shouldHideTabBar ? 0 : 1
                self.layoutIfNeeded()
            },
            completion: { _ in completion() }
        )
    }
}

private extension RootView {
    @objc func panGestureResponder(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began, .possible:
            if containerViewMinHeightConstraint == nil {
                containerViewMinHeightConstraint = containerView.heightAnchor.constraint(
                    greaterThanOrEqualToConstant: tabBar.bounds.height + safeAreaInsets.bottom + headerView.bounds.height
                )
                containerViewMinHeightConstraint?.isActive = true
            }
            containerViewOriginalOffset = containerView.bounds.height
            if containerViewTopConstraint == nil {
                containerViewTopConstraint = bottomAnchor.constraint(
                    equalTo: containerView.topAnchor,
                    constant: containerViewOriginalOffset
                )
                containerViewTopConstraint?.priority = UILayoutPriority(900)
                containerViewTopConstraint?.isActive = true
            } else {
                containerViewTopConstraint?.constant = containerViewOriginalOffset
            }
        case .ended:
            let translation = gesture.translation(in: contentView)
            let velocity = gesture.velocity(in: contentView)
            let totalTranslationY = translation.y + velocity.y * Constants.animationDuration
            let finalPositionY = max(min(containerViewOriginalOffset - totalTranslationY, bounds.height), 0)
            switch (finalPositionY / bounds.height) {
            case Constants.topRange:
                containerViewTopConstraint?.constant = .greatestFiniteMagnitude
            case Constants.bottomRange:
                containerViewTopConstraint?.constant = 0
            default:
                containerViewTopConstraint?.isActive = false
                containerViewTopConstraint = nil
            }
            UIView.animate(withDuration: Constants.animationDuration, animations: layoutIfNeeded)
        case .failed, .cancelled:
            containerViewTopConstraint?.constant = containerViewOriginalOffset
            UIView.animate(withDuration: Constants.animationDuration, animations: layoutIfNeeded)
        case .changed:
            let translation = gesture.translation(in: contentView)
            containerViewTopConstraint?.constant = containerViewOriginalOffset - translation.y
        @unknown default:
            fatalError()
        }
    }
}

private enum Constants {
    static let bottomRange: ClosedRange<CGFloat> = 0 ... 0.2
    static let topRange: ClosedRange<CGFloat> = 0.8 ... 1
    static let cornerRadius: CGFloat = 16
    static let animationDuration: TimeInterval = 0.3
}
