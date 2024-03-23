//
//  AccessoriesViewController.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 13/03/24.
//

import UIKit
import Combine
import UniformTypeIdentifiers

final class AccessoriesViewController: UIViewController, ContentController {
    
    weak var containerController: ContainerController?
    var accessoriesView: AccessoriesView { view as! AccessoriesView }
    var tableView: UITableView { accessoriesView.tableView }
    
    override var title: String? {
        get { "Accessories" }
        set {}
    }
    
    override var toolbarItems: [UIBarButtonItem]? {
        get { [.init(image: UIImage(systemName: "plus"), style: .done, target: self, action: #selector(importAccessory))] }
        set {}
    }
    
    override var tabBarItem: UITabBarItem! {
        get { Constants.tabBarItem }
        set {}
    }
    
    override var preferredContentSize: CGSize {
        get { Constants.preferredContentSize }
        set {}
    }
    
    private let accessoriesProvider: AccessoriesProvider
    private let accessoryModifier: AccessoryModifier
    private let accessoryCreator: AccessoryCreator
    private let accessoriesImporter: AccessoriesImporter
    private let didSelectAccessory: PassthroughSubject<Accessory, Never> = .init()
    private var accessoriesCache: [Accessory] = []
    private var cancellables: Set<AnyCancellable> = []
    
    init(
        accessoriesProvider: AccessoriesProvider,
        accessoryModifier: AccessoryModifier,
        accessoryCreator: AccessoryCreator,
        accessoriesImporter: AccessoriesImporter
    ) {
        self.accessoriesProvider = accessoriesProvider
        self.accessoryModifier = accessoryModifier
        self.accessoryCreator = accessoryCreator
        self.accessoriesImporter = accessoriesImporter
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = AccessoriesView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellReuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        
        didSelectAccessory
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self, accessoriesProvider] accessory in
                let history = AccessoryHistoryViewController(
                    accessoryId: accessory.id,
                    accessoriesProvider: accessoriesProvider
                )
                history.parentContentController = self
                self?.containerController?.show(contentController: history)
            })
            .store(in: &cancellables)
        
        accessoriesProvider.accessories()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] accessories in
                self?.accessoriesCache = accessories
                self?.tableView.reloadData()
                if accessories.isEmpty {
                    var configuration = UIContentUnavailableConfiguration.empty()
                    configuration.text = "No Accessories"
                    configuration.secondaryText = "There doesn't seem to be any imported accessories."
                    configuration.image = UIImage(systemName: "tag.slash")
                    self?.contentUnavailableConfiguration = configuration
                } else {
                    self?.contentUnavailableConfiguration = nil
                }
            })
            .store(in: &cancellables)
    }
    
    func mapRenderer() -> MapRenderer? {
        AccessoriesMapRenderer(accessoriesProvider: accessoriesProvider, didSelectAccessory: didSelectAccessory)
    }
}

extension AccessoriesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        accessoriesCache.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellReuseIdentifier, for: indexPath)
        guard indexPath.row < accessoriesCache.count else { return cell }
        let accessory = accessoriesCache[indexPath.row]
        
        var background = cell.defaultBackgroundConfiguration()
        background.backgroundColor = .clear
        cell.backgroundConfiguration = background
        
        var content = cell.defaultContentConfiguration()
        content.image = UIImage(systemName: accessory.imageName)
        content.imageProperties.tintColor = UIColor(accessory.color)
        content.text = accessory.name
        content.secondaryText = accessory.latestLocation.map { latestLocation in
            if let address = latestLocation.address {
                return "Last seen \(Constants.dateFormatter.localizedString(for: latestLocation.timestamp, relativeTo: Date())) at \(address)"
            } else {
                return "Last seen \(Constants.dateFormatter.localizedString(for: latestLocation.timestamp, relativeTo: Date()))"
            }
        }
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content
        cell.accessoryView = UIView(frame: .init(x: 0, y: 0, width: 8, height: 8))
        switch accessory.status {
        case .connected:
            cell.accessoryView?.backgroundColor = .systemGreen
        case .active:
            cell.accessoryView?.backgroundColor = .systemOrange
        case .inactive:
            cell.accessoryView?.backgroundColor = .systemRed
        }
        cell.accessoryView?.layer.cornerRadius = 4
        
        return cell
    }
}

extension AccessoriesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < accessoriesCache.count else { return }
        let accessory = accessoriesCache[indexPath.row]
        didSelectAccessory.send(accessory)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: "Delete",
            handler: { [weak self] _, _, completion in
                guard let accessoryId = self?.accessoriesCache[indexPath.row].id else {
                    completion(false)
                    return
                }
                
                self?.accessoryModifier.deleteAccessory(with: accessoryId)
                completion(true)
            }
        )
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash.fill")
        
        let editAction = UIContextualAction(
            style: .normal,
            title: "Edit",
            handler: { [weak self, accessoryModifier] _, _, completion in
                defer { completion(false) }
                guard let accessory = self?.accessoriesCache[indexPath.row] else { return }
                let editor = AccessoryEditorViewController(accessory: accessory, accessoryModifier: accessoryModifier)
                self?.present(editor, animated: true)
            }
        )
        editAction.backgroundColor = .systemBrown
        editAction.image = UIImage(systemName: "square.and.pencil")
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(
            actionProvider: { [weak self, accessoryModifier] _ in
                let copyKeyIdAction = UIAction(
                    title: "Copy advertisement key (Base64)",
                    image: UIImage(systemName: "doc.on.clipboard.fill"),
                    handler: { _ in
                        guard let accessoryId = self?.accessoriesCache[indexPath.row].id else { return }
                        UIPasteboard.general.string = accessoryId
                    }
                )
                
                let modifyAction = UIAction(
                    title: "Edit",
                    image: UIImage(systemName: "square.and.pencil"),
                    handler: { _ in
                        guard let accessory = self?.accessoriesCache[indexPath.row] else { return }
                        let editor = AccessoryEditorViewController(accessory: accessory, accessoryModifier: accessoryModifier)
                        self?.present(editor, animated: true)
                    }
                )
                
                let deleteAction = UIAction(
                    title: "Delete accessory",
                    image: UIImage(systemName: "trash.fill"),
                    attributes: .destructive,
                    handler: { _ in
                        guard let accessoryId = self?.accessoriesCache[indexPath.row].id else { return }
                        self?.accessoryModifier.deleteAccessory(with: accessoryId)
                    })
                                                
                return UIMenu(title: "", children: [copyKeyIdAction, modifyAction, deleteAction])
            }
        )
    }
}

private extension AccessoriesViewController {
    @objc
    func importAccessory(_ sender: UIView) {
        let sheet = UIAlertController(
            title: "Add Accessory",
            message: "Choose how would you like to add your accessory.",
            preferredStyle: .actionSheet
        )
        
        sheet.addAction(
            .init(
                title: "Create new one",
                style: .default,
                handler: { [accessoryCreator] _ in accessoryCreator.createNewAccessory() }
            )
        )
        
        sheet.addAction(
            .init(
                title: "Import from plist",
                style: .default,
                handler: { [weak self, accessoriesImporter] _ in
                    let picker = DocumentPickerViewController(forOpeningContentTypes: [.propertyList]) { (url: URL?) in
                        guard let url = url else { return }
                        accessoriesImporter.importAccessories(from: url)
                    }
                                        
                    self?.present(picker, animated: true, completion: nil)
                }
            )
        )
        
        sheet.addAction(
            .init(
                title: "Cancel",
                style: .cancel
            )
        )
        
        sheet.popoverPresentationController?.sourceView = sender
        sheet.popoverPresentationController?.sourceRect = sender.bounds
        
        present(sheet, animated: true)
    }
}

private enum Constants {
    static let tabBarItem = UITabBarItem(
        title: "Accessories",
        image: UIImage(systemName: "map"),
        selectedImage: UIImage(systemName: "map.fill")
    )
    static let preferredContentSize = CGSize(
        width: CGFloat.greatestFiniteMagnitude,
        height: 200
    )
    static let cellReuseIdentifier = "cell"
    static let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateTimeStyle = .named
        formatter.formattingContext = .middleOfSentence
        formatter.unitsStyle = .full
        return formatter
    }()
}
