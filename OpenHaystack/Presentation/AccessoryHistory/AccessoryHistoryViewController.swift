//
//  AccessoryHistoryViewController.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 15/03/24.
//

import UIKit
import Combine

final class AccessoryHistoryViewController: UIViewController, ContentController {
    weak var containerController: ContainerController?
    weak var parentContentController: ContentController?
    var accessoryHistoryView: AccessoryHistoryView { view as! AccessoryHistoryView }
    var tableView: UITableView { accessoryHistoryView.tableView }
    
    override var toolbarItems: [UIBarButtonItem]? {
        get { [.init(image: UIImage(systemName: "xmark.circle"), style: .plain, target: self, action: #selector(close))] }
        set {}
    }
    
    override var hidesBottomBarWhenPushed: Bool {
        get { true }
        set {}
    }
    
    override var title: String? {
        get { "History" }
        set {}
    }
    
    override var preferredContentSize: CGSize {
        get { Constants.preferredContentSize }
        set {}
    }
    
    private let accessoryId: String
    private let accessoriesProvider: AccessoriesProvider
    private var accessoryCache: Accessory?
    private var cancellables: Set<AnyCancellable> = []
    private let didTapLocation: PassthroughSubject<Location, Never> = .init()
    
    init(
        accessoryId: String,
        accessoriesProvider: AccessoriesProvider
    ) {
        self.accessoryId = accessoryId
        self.accessoriesProvider = accessoriesProvider
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = AccessoryHistoryView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellReuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        
        accessoriesProvider.accessories()
            .compactMap { [accessoryId] in $0.first(where: { $0.id == accessoryId }) }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] accessory in
                self?.accessoryCache = accessory
                self?.tableView.reloadData()
                if accessory.locations.isEmpty {
                    var configuration = UIContentUnavailableConfiguration.empty()
                    configuration.text = "No Location"
                    configuration.secondaryText = "No location records were found for this accessory."
                    configuration.image = UIImage(systemName: "mappin.slash")
                    self?.contentUnavailableConfiguration = configuration
                } else {
                    self?.contentUnavailableConfiguration = nil
                }
            })
            .store(in: &cancellables)
    }
    
    func mapRenderer() -> MapRenderer? {
        AccessoryHistoryMapRenderer(
            accessoryId: accessoryId,
            accessoriesProvider: accessoriesProvider, 
            didTapLocation: didTapLocation
        )
    }
}

extension AccessoryHistoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        accessoryCache?.locations.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellReuseIdentifier, for: indexPath)
        guard let accessory = accessoryCache else { return cell }

        var background = cell.defaultBackgroundConfiguration()
        background.backgroundColor = .clear
        cell.backgroundConfiguration = background
        
        var content = cell.defaultContentConfiguration()
        content.image = {
            let layer = LocationDotLayer()
            layer.fillColor = indexPath.row == 0 ? UIColor.accent.cgColor : UIColor.systemGray.cgColor
            return layer.drawImage(frame: layer.path.unsafelyUnwrapped.boundingBox.padBy(dx: layer.lineWidth / 2, dy: layer.lineWidth / 2))
        }()
        if let address = accessory.locations[indexPath.row].address,
           !address.isEmpty {
            content.text = address
        } else {
            content.text = "\(accessory.locations[indexPath.row].latitude), \(accessory.locations[indexPath.row].longitude)"
        }
        content.secondaryText = """
        \(Constants.dateFormatter.string(from: accessory.locations[indexPath.row].timestamp))
        Accuracy: \(accessory.locations[indexPath.row].accuracy)\(accessory.locations[indexPath.row].confidence.map { ", Confidence: \($0)" } ?? "")
        """
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content
        if indexPath.row == 0 {
            cell.accessoryView = {
                let label = UILabel(frame: .init(x: 0, y: 0, width: 50, height: 16))
                label.text = "Latest"
                label.textAlignment = .center
                label.layer.cornerRadius = 8
                label.clipsToBounds = true
                label.font = .preferredFont(forTextStyle: .caption1)
                label.textColor = UIColor.accent
                label.backgroundColor = UIColor.accent.withAlphaComponent(0.3)
                return label
            }()
        } else {
            cell.accessoryView = nil
        }
        
        return cell
    }
}

extension AccessoryHistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard 
            indexPath.row < accessoryCache?.locations.count ?? 0,
            let location = accessoryCache?.locations[indexPath.row]
        else { return }
        didTapLocation.send(location)
    }
}

private extension AccessoryHistoryViewController {
    @objc
    func close() {
        guard let parentContentController else { return }
        containerController?.show(contentController: parentContentController)
    }
}

private enum Constants {
    static let preferredContentSize = CGSize(
        width: CGFloat.nan,
        height: 300
    )
    static let cellReuseIdentifier = "cell"
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
}
