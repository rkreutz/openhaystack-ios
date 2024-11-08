//
//  SettingsViewController.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 14/03/24.
//

import UIKit

final class SettingsViewController: UIViewController, ContentController {
    weak var containerController: ContainerController?
    var settingsView: SettingsView { view as! SettingsView }
    var urlTextField: UITextField { settingsView.urlTextField }
    var authorizationSwitch: UISwitch { settingsView.authorizationSwitch }
    var authorizationTextField: UITextField { settingsView.authorizationTextField }
    var daysStepper: UIStepper { settingsView.daysStepper }
    
    private var serverConfiguration = ServerConfiguration.current() {
        didSet {
            serverConfiguration.saveAsCurrent()
        }
    }
    
    private var reportsConfiguration = ReportsConfiguration.current() {
        didSet {
            reportsConfiguration.saveAsCurrent()
        }
    }
    
    override var title: String? {
        get { "Settings" }
        set {}
    }
    
    override var preferredContentSize: CGSize {
        get { CGSize.init(width: CGFloat.nan, height: .nan) }
        set {}
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = SettingsView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        urlTextField.text = serverConfiguration.serverUrl
        switch serverConfiguration.authorizationType {
        case .none:
            authorizationSwitch.isOn = false
            authorizationTextField.isEnabled = false
            authorizationTextField.text = nil
        case .httpHeader(let header):
            authorizationSwitch.isOn = true
            authorizationTextField.isEnabled = true
            authorizationTextField.text = header
        }
        
        urlTextField.delegate = self
        authorizationTextField.delegate = self
        
        urlTextField.addTarget(self, action: #selector(didUpdateUrl(_:)), for: .editingChanged)
        authorizationSwitch.addTarget(self, action: #selector(didChangeSwitch(_:)), for: .valueChanged)
        authorizationTextField.addTarget(self, action: #selector(didUpdateAuthorization(_:)), for: .editingChanged)
        
        daysStepper.minimumValue = 1
        daysStepper.maximumValue = 21
        daysStepper.value = Double(reportsConfiguration.numberOfDays)
        daysStepper.addTarget(self, action: #selector(didUpdateStepper), for: .valueChanged)
    }
    
    func mapRenderer() -> MapRenderer? { nil }
}

private extension SettingsViewController {
    @objc
    func didUpdateUrl(_ sender: UITextField) {
        serverConfiguration.serverUrl = sender.text
    }
    
    @objc
    func didChangeSwitch(_ sender: UISwitch) {
        if sender.isOn {
            serverConfiguration.authorizationType = .httpHeader(authorizationTextField.text ?? "")
        } else {
            serverConfiguration.authorizationType = .none
            authorizationTextField.text = nil
        }
        authorizationTextField.isEnabled = sender.isOn
    }
    
    @objc
    func didUpdateAuthorization(_ sender: UITextField) {
        guard case .httpHeader = serverConfiguration.authorizationType else { return }
        serverConfiguration.authorizationType = .httpHeader(sender.text ?? "")
    }
    
    @objc
    func didUpdateStepper(_ sender: UIStepper) {
        reportsConfiguration.numberOfDays = Int(sender.value)
    }
}

extension SettingsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
