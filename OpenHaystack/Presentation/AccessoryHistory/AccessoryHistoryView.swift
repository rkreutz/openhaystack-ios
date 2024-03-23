//
//  AccessoryHistoryView.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 15/03/24.
//

import UIKit

final class AccessoryHistoryView: UIView {
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    private var hasSetup: Bool = false
    
    init() {
        super.init(frame: .zero)
        addSubview(tableView)
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
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}
