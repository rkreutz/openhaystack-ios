//
//  HeaderView.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 14/03/24.
//

import UIKit

final class HeaderView: UIView {
    var title: String? {
        get { label.text }
        set { label.text = newValue }
    }
    
    var barButtonItems: [UIBarButtonItem]? {
        didSet {
            buttonStackView.arrangedSubviews.forEach { arrangedSubview in
                buttonStackView.removeArrangedSubview(arrangedSubview)
                arrangedSubview.removeFromSuperview()
            }
            barButtonItems?
                .map { buttonItem -> UIButton in
                    let button: UIButton
                    switch buttonItem.style {
                    case .plain:
                        button = UIButton(configuration: .plain())
                    case .done:
                        button = UIButton(configuration: .borderedTinted())
                    case .bordered:
                        button = UIButton(configuration: .bordered())
                    @unknown default:
                        button = UIButton(configuration: .plain())
                    }
                    if let target = buttonItem.target,
                       let action = buttonItem.action {
                        button.addTarget(target, action: action, for: .touchUpInside)
                    }
                    button.tintColor = buttonItem.tintColor
                    button.setImage(buttonItem.image, for: .normal)
                    return button
                }
                .forEach { buttonStackView.addArrangedSubview($0) }
        }
    }
    
    private let handleView: UIView = {
        let handleView = UIView()
        handleView.translatesAutoresizingMaskIntoConstraints = false
        handleView.backgroundColor = UIColor.systemFill
        handleView.layer.cornerRadius = Constants.handleSize.height / 2
        return handleView
    }()
    
    private let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.spacing = 8
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = .init(top: 8, left: 16, bottom: 8, right: 16)
        stackView.traitOverrides[UITraitLayoutDirection.self] = .rightToLeft
        stackView.setContentCompressionResistancePriority(.required, for: .horizontal)
        stackView.setContentHuggingPriority(.required, for: .horizontal)
        return stackView
    }()
    
    private let separatorView: UIView = {
        let separatorView = UIView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = .separator
        return separatorView
    }()
    
    private var hasSetup: Bool = false
    
    init() {
        super.init(frame: .zero)
        addSubview(label)
        addSubview(buttonStackView)
        addSubview(handleView)
        addSubview(separatorView)
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
            handleView.widthAnchor.constraint(equalToConstant: Constants.handleSize.width),
            handleView.heightAnchor.constraint(equalToConstant: Constants.handleSize.height),
            handleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            handleView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
        ])
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: buttonStackView.leadingAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: 16),
            label.heightAnchor.constraint(equalToConstant: Constants.headerHeight),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            buttonStackView.topAnchor.constraint(equalTo: topAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        NSLayoutConstraint.activate([
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1),
        ])
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Constants.headerHeight)
        ])
    }
}

private enum Constants {
    static let handleSize: CGSize = .init(width: 32, height: 6)
    static let headerHeight: CGFloat = 56
}
