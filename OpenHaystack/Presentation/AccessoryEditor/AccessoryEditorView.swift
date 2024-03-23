//
//  AccessoryEditorView.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 22/03/24.
//

import UIKit

final class AccessoryEditorView: UIView {
    let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Save", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        return button
    }()
    
    let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Cancel", for: .normal)
        return button
    }()
    
    private let firstSectionView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.backgroundColor = .secondarySystemBackground
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.text = "Name"
        return label
    }()
    
    let nameTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .default
        textField.textColor = .secondaryLabel
        textField.textAlignment = .right
        return textField
    }()
    
    private let nameSeparator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .separator
        return view
    }()
    
    private let imageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.text = "Icon"
        return label
    }()
    
    let imageButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "photo"), for: .normal)
        button.setContentHuggingPriority(.required, for: .vertical)
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        button.contentHorizontalAlignment = .trailing
        return button
    }()
    
    private let imageSeparator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .separator
        return view
    }()
    
    private let colorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.text = "Color"
        return label
    }()
    
    let colorButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIColor.white.drawCircle(diameter: 24), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .trailing
        return button
    }()
    
    private var hasSetup: Bool = false
    
    init() {
        super.init(frame: .zero)
        backgroundColor = .systemBackground
        addSubview(cancelButton)
        addSubview(saveButton)
        addSubview(firstSectionView)
        firstSectionView.addSubview(nameLabel)
        firstSectionView.addSubview(nameTextField)
        firstSectionView.addSubview(nameSeparator)
        firstSectionView.addSubview(imageLabel)
        firstSectionView.addSubview(imageButton)
        firstSectionView.addSubview(imageSeparator)
        firstSectionView.addSubview(colorLabel)
        firstSectionView.addSubview(colorButton)
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
            cancelButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
            cancelButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8)
        ])
        
        NSLayoutConstraint.activate([
            saveButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            saveButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8)
        ])
        
        NSLayoutConstraint.activate([
            firstSectionView.topAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: 16),
            firstSectionView.bottomAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
            firstSectionView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            firstSectionView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: firstSectionView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: firstSectionView.leadingAnchor, constant: 16),
        ])
                
        NSLayoutConstraint.activate([
            nameTextField.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            nameTextField.trailingAnchor.constraint(equalTo: firstSectionView.trailingAnchor, constant: -16),
            nameTextField.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8)
        ])
        
        NSLayoutConstraint.activate([
            nameSeparator.heightAnchor.constraint(equalToConstant: 1),
            nameSeparator.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 16),
            nameSeparator.leadingAnchor.constraint(equalTo: firstSectionView.leadingAnchor, constant: 16),
            nameSeparator.trailingAnchor.constraint(equalTo: firstSectionView.trailingAnchor, constant: -16),
        ])
        
        NSLayoutConstraint.activate([
            imageLabel.topAnchor.constraint(equalTo: nameSeparator.bottomAnchor, constant: 16),
            imageLabel.leadingAnchor.constraint(equalTo: firstSectionView.leadingAnchor, constant: 16),
        ])
        
        NSLayoutConstraint.activate([
            imageButton.centerYAnchor.constraint(equalTo: imageLabel.centerYAnchor),
            imageButton.trailingAnchor.constraint(equalTo: firstSectionView.trailingAnchor, constant: -16),
            imageButton.leadingAnchor.constraint(equalTo: imageLabel.trailingAnchor, constant: 8)
        ])
        
        NSLayoutConstraint.activate([
            imageSeparator.heightAnchor.constraint(equalToConstant: 1),
            imageSeparator.topAnchor.constraint(equalTo: imageLabel.bottomAnchor, constant: 16),
            imageSeparator.leadingAnchor.constraint(equalTo: firstSectionView.leadingAnchor, constant: 16),
            imageSeparator.trailingAnchor.constraint(equalTo: firstSectionView.trailingAnchor, constant: -16),
        ])
        
        NSLayoutConstraint.activate([
            colorLabel.topAnchor.constraint(equalTo: imageSeparator.bottomAnchor, constant: 16),
            colorLabel.bottomAnchor.constraint(equalTo: firstSectionView.bottomAnchor, constant: -16),
            colorLabel.leadingAnchor.constraint(equalTo: firstSectionView.leadingAnchor, constant: 16),
        ])
        
        NSLayoutConstraint.activate([
            colorButton.centerYAnchor.constraint(equalTo: colorLabel.centerYAnchor),
            colorButton.trailingAnchor.constraint(equalTo: firstSectionView.trailingAnchor, constant: -16),
            colorButton.leadingAnchor.constraint(equalTo: colorLabel.trailingAnchor, constant: 8)
        ])
    }
}
