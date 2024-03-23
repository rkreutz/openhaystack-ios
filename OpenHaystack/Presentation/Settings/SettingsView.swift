//
//  SettingsView.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 14/03/24.
//

import UIKit

final class SettingsView: UIView {
    enum Constants {
        static let animationDuration: TimeInterval = 0.3
    }
    
    private let firstSectionHeader: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "SERVER"
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    
    private let firstSectionFooter: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = """
        Specify the proxy server from which location reports should be fetched.
        
        Additionally you may specify the authorization header needed to access the provided server.
        """
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.numberOfLines = 0
        return label
    }()
    
    private let firstSectionView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.backgroundColor = .systemFill
        return view
    }()
    
    let urlTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "URL to server"
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.returnKeyType = .done
        textField.enablesReturnKeyAutomatically = true
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.textContentType = .URL
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .clear
        textField.keyboardType = .URL
        textField.setContentHuggingPriority(.required, for: .vertical)
        textField.setContentCompressionResistancePriority(.required, for: .vertical)
        return textField
    }()
    
    private let authorizationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Requires authorization"
        return label
    }()
    
    let authorizationSwitch: UISwitch = {
        let uiSwitch = UISwitch()
        uiSwitch.translatesAutoresizingMaskIntoConstraints = false
        uiSwitch.setContentHuggingPriority(.required, for: .vertical)
        uiSwitch.setContentCompressionResistancePriority(.required, for: .vertical)
        return uiSwitch
    }()
    
    let authorizationTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Authorization-Header value"
        textField.returnKeyType = .done
        textField.enablesReturnKeyAutomatically = true
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .clear
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.textContentType = .URL
        textField.keyboardType = .asciiCapable
        textField.setContentHuggingPriority(.required, for: .vertical)
        textField.setContentCompressionResistancePriority(.required, for: .vertical)
        return textField
    }()
    
    private let secondSectionHeader: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "LOCATION REPORTS"
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    
    private let secondSectionFooter: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = """
        Specify how many days worth of location updates should be fetched.
        """
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.numberOfLines = 0
        return label
    }()
    
    private let secondSectionView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.backgroundColor = .systemFill
        return view
    }()
    
    private let daysLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Days"
        return label
    }()
    
    private let stepperLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    
    let daysStepper: UIStepper = {
        let stepper = UIStepper()
        stepper.translatesAutoresizingMaskIntoConstraints = false
        stepper.setContentHuggingPriority(.required, for: .vertical)
        stepper.setContentHuggingPriority(.required, for: .horizontal)
        stepper.setContentCompressionResistancePriority(.required, for: .vertical)
        stepper.setContentCompressionResistancePriority(.required, for: .horizontal)
        return stepper
    }()
    
    private var hasSetup: Bool = false
    private var serverTextFieldKeyboardConstraint: NSLayoutConstraint?
    private var authorizationTextFieldKeyboardConstraint: NSLayoutConstraint?
    private var subscriptions: [NSObjectProtocol] = []
    
    init() {
        super.init(frame: .zero)
        addSubview(firstSectionHeader)
        addSubview(firstSectionView)
        firstSectionView.addSubview(urlTextField)
        firstSectionView.addSubview(authorizationLabel)
        firstSectionView.addSubview(authorizationSwitch)
        firstSectionView.addSubview(authorizationTextField)
        addSubview(firstSectionFooter)
        addSubview(secondSectionHeader)
        addSubview(secondSectionView)
        secondSectionView.addSubview(daysLabel)
        secondSectionView.addSubview(daysStepper)
        secondSectionView.addSubview(stepperLabel)
        addSubview(secondSectionFooter)
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
            firstSectionHeader.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 12),
            firstSectionHeader.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 32),
            firstSectionHeader.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -32),
        ])
        
        NSLayoutConstraint.activate([
            firstSectionView.topAnchor.constraint(equalTo: firstSectionHeader.bottomAnchor, constant: 4),
            firstSectionView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            firstSectionView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
        ])
        
        NSLayoutConstraint.activate([
            urlTextField.topAnchor.constraint(equalTo: firstSectionView.topAnchor, constant: 16),
            urlTextField.centerXAnchor.constraint(equalTo: firstSectionView.centerXAnchor),
            urlTextField.leadingAnchor.constraint(equalTo: firstSectionView.leadingAnchor, constant: 16),
        ])
        serverTextFieldKeyboardConstraint = urlTextField.bottomAnchor.constraint(lessThanOrEqualTo: keyboardLayoutGuide.topAnchor, constant: -16)
        
        NSLayoutConstraint.activate([
            authorizationSwitch.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 16),
            authorizationSwitch.trailingAnchor.constraint(equalTo: firstSectionView.trailingAnchor, constant: -16),
        ])
        
        NSLayoutConstraint.activate([
            authorizationLabel.centerYAnchor.constraint(equalTo: authorizationSwitch.centerYAnchor),
            authorizationLabel.leadingAnchor.constraint(equalTo: firstSectionView.leadingAnchor, constant: 16),
            authorizationLabel.trailingAnchor.constraint(equalTo: authorizationSwitch.leadingAnchor),
        
        ])
        
        NSLayoutConstraint.activate([
            authorizationTextField.topAnchor.constraint(equalTo: authorizationSwitch.bottomAnchor, constant: 8),
            authorizationTextField.leadingAnchor.constraint(equalTo: firstSectionView.leadingAnchor, constant: 16),
            authorizationTextField.trailingAnchor.constraint(equalTo: firstSectionView.trailingAnchor, constant: -16),
            authorizationTextField.bottomAnchor.constraint(equalTo: firstSectionView.bottomAnchor, constant: -16),
        ])
        authorizationTextFieldKeyboardConstraint = authorizationTextField.bottomAnchor.constraint(lessThanOrEqualTo: keyboardLayoutGuide.topAnchor, constant: -16)
        
        NSLayoutConstraint.activate([
            firstSectionFooter.topAnchor.constraint(equalTo: firstSectionView.bottomAnchor, constant: 8),
            firstSectionFooter.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            firstSectionFooter.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
        ])
        
        NSLayoutConstraint.activate([
            secondSectionHeader.topAnchor.constraint(equalTo: firstSectionFooter.bottomAnchor, constant: 24),
            secondSectionHeader.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            secondSectionHeader.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
        ])
        
        NSLayoutConstraint.activate([
            secondSectionView.topAnchor.constraint(equalTo: secondSectionHeader.bottomAnchor, constant: 4),
            secondSectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            secondSectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])
        
        NSLayoutConstraint.activate([
            secondSectionFooter.topAnchor.constraint(equalTo: secondSectionView.bottomAnchor, constant: 8),
            secondSectionFooter.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            secondSectionFooter.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            {
                let constraint = secondSectionFooter.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
                constraint.priority = .defaultHigh
                return constraint
            }()
        ])
        
        NSLayoutConstraint.activate([
            daysStepper.topAnchor.constraint(equalTo: secondSectionView.topAnchor, constant: 8),
            daysStepper.trailingAnchor.constraint(equalTo: secondSectionView.trailingAnchor, constant: -16),
            daysStepper.bottomAnchor.constraint(equalTo: secondSectionView.bottomAnchor, constant: -8)
        ])
        
        NSLayoutConstraint.activate([
            stepperLabel.centerYAnchor.constraint(equalTo: daysStepper.centerYAnchor),
            stepperLabel.trailingAnchor.constraint(equalTo: daysStepper.leadingAnchor, constant: -8)
        ])
        
        NSLayoutConstraint.activate([
            daysLabel.centerYAnchor.constraint(equalTo: daysStepper.centerYAnchor),
            daysLabel.leadingAnchor.constraint(equalTo: secondSectionView.leadingAnchor, constant: 16),
            daysLabel.trailingAnchor.constraint(equalTo: stepperLabel.leadingAnchor, constant: -8)
        ])
        
        daysStepper.addObserver(self, forKeyPath: "value", context: nil)
        daysStepper.addTarget(self, action: #selector(stepperUpdate), for: .valueChanged)
        stepperUpdate()
        
        subscriptions.append(
            NotificationCenter.default.addObserver(
                forName: UIApplication.keyboardWillShowNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.serverTextFieldKeyboardConstraint?.isActive = self?.urlTextField.isFirstResponder ?? false
                self?.authorizationTextFieldKeyboardConstraint?.isActive = self?.authorizationTextField.isFirstResponder ?? false
            }
        )
        
        subscriptions.append(
            NotificationCenter.default.addObserver(
                forName: UIApplication.keyboardDidHideNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.serverTextFieldKeyboardConstraint?.isActive = false
                self?.authorizationTextFieldKeyboardConstraint?.isActive = false
            }
        )
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch (object, keyPath) {
        case (let stepper as UIStepper, "value") where stepper == daysStepper:
            stepperUpdate()
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

private extension SettingsView {
    @objc
    func stepperUpdate() {
        stepperLabel.text = "\(Int(daysStepper.value))"
    }
}
