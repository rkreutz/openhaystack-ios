//
//  AccessoryEditorViewController.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 22/03/24.
//

import UIKit

final class AccessoryEditorViewController: UIViewController {
    
    var accessoryEditorView: AccessoryEditorView { view as! AccessoryEditorView }
    var cancelButton: UIButton { accessoryEditorView.cancelButton }
    var saveButton: UIButton { accessoryEditorView.saveButton }
    var nameTextField: UITextField { accessoryEditorView.nameTextField }
    var imageButton: UIButton { accessoryEditorView.imageButton }
    var colorButton: UIButton { accessoryEditorView.colorButton }
    
    private var accessory: Accessory
    private let accessoryModifier: AccessoryModifier
    
    init(accessory: Accessory, accessoryModifier: AccessoryModifier) {
        self.accessory = accessory
        self.accessoryModifier = accessoryModifier
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = AccessoryEditorView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.text = accessory.name
        imageButton.setImage(UIImage(systemName: accessory.imageName), for: .normal)
        colorButton.setImage(UIColor(accessory.color).drawCircle(diameter: 24), for: .normal)
        
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        nameTextField.addTarget(self, action: #selector(textFieldUpdated), for: .editingChanged)
        nameTextField.delegate = self
        
        let imageActions = Accessory.Constants.icons
            .map { imageName in
                UIAction(
                    image: UIImage(systemName: imageName),
                    handler: { [weak self] _ in 
                        self?.accessory.imageName = imageName
                        self?.imageButton.setImage(UIImage(systemName: imageName), for: .normal)
                    }
                )
            }
        imageButton.menu = UIMenu(options: .displayAsPalette, children: imageActions)
        imageButton.showsMenuAsPrimaryAction = true
        
        let colorActions = Accessory.Constants.colors
            .map { color in
                UIAction(
                    image: UIColor(color).drawCircle(diameter: 32),
                    handler: { [weak self] _ in
                        self?.accessory.color = color
                        self?.colorButton.setImage(UIColor(color).drawCircle(diameter: 24), for: .normal)
                    }
                )
            }
        colorButton.menu = UIMenu(options: .displayAsPalette, children: colorActions)
        colorButton.showsMenuAsPrimaryAction = true
    }
}

extension AccessoryEditorViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}

private extension AccessoryEditorViewController {
    @objc
    func cancel() {
        dismiss(animated: true)
    }
    
    @objc
    func save() {
        accessoryModifier.update(accessory: accessory)
        dismiss(animated: true)
    }
    
    @objc
    func textFieldUpdated(_ sender: UITextField) {
        accessory.name = sender.text ?? ""
        saveButton.isEnabled = !accessory.name.isEmpty
    }
}
