//
//  DocumentPickerViewController.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 22/03/24.
//

import UIKit
import UniformTypeIdentifiers

final class DocumentPickerViewController: UIDocumentPickerViewController {
    
    private let handler: ([URL]?) -> Void
    init(forOpeningContentTypes types: [UTType], completion: @escaping (URL?) -> Void) {
        self.handler = { completion($0?.first) }
        super.init(forOpeningContentTypes: types, asCopy: true)
        self.allowsMultipleSelection = false
        self.delegate = self
    }
    
    init(forOpeningContentTypes types: [UTType], completion: @escaping ([URL]?) -> Void) {
        self.handler = completion
        super.init(forOpeningContentTypes: types, asCopy: true)
        self.allowsMultipleSelection = true
        self.delegate = self
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DocumentPickerViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        handler(urls)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        handler(nil)
    }
}
