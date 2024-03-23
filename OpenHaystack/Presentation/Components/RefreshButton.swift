//
//  RefreshButton.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 20/03/24.
//

import UIKit

final class RefreshButton: UIButton {
    var isRefreshing: Bool {
        get { activityIndicator.isAnimating }
        set {
            if newValue {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
            imageView?.isHidden = newValue
            isUserInteractionEnabled = !newValue
        }
    }
    
    override var tintColor: UIColor! {
        get { super.tintColor }
        set {
            super.tintColor = newValue
            activityIndicator.color = titleColor(for: .normal)
        }
    }
    
    private let activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.layer.cornerRadius = Constants.size.height / 2
        activityIndicator.clipsToBounds = true
        return activityIndicator
    }()

    private var hasSetup: Bool = false
    
    init() {
        super.init(frame: .zero)
        configuration = .filled()
        layer.cornerRadius = Constants.size.height / 2
        clipsToBounds = true
        setImage(Constants.image, for: .normal)
        addSubview(activityIndicator)
        addTarget(self, action: #selector(startRefreshing), for: .touchUpInside)
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
            widthAnchor.constraint(equalToConstant: Constants.size.width),
            heightAnchor.constraint(equalToConstant: Constants.size.height)
        ])
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            activityIndicator.widthAnchor.constraint(equalToConstant: Constants.size.width),
            activityIndicator.heightAnchor.constraint(equalToConstant: Constants.size.height),
        ])
    }
}

private extension RefreshButton {
    @objc
    func startRefreshing() {
        isRefreshing = true
    }
}

private enum Constants {
    static let image = UIImage(systemName: "arrow.clockwise")
    static let size: CGSize = .init(width: 44, height: 44)
}
