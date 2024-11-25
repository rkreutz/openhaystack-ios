//
//  MemoryCache.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 22/11/24.
//

import Foundation
import Combine

public final class MemoryCache<Key: Hashable, Value>: ExpressibleByDictionaryLiteral {

    private var cache: [Key: Value] = [:]
    private var subjects: [Key: CurrentValueSubject<Value?, Never>] = [:]
    private let queue = DispatchQueue(label: "com.rkreutz.MemoryCache", attributes: [.concurrent])

    public init() {}

    public required init(dictionaryLiteral elements: (Key, Value)...) {
        cache = .init(uniqueKeysWithValues: elements)
    }

    public subscript(_ key: Key) -> Value? {
        get { queue.sync { cache[key] } }
        set {
            queue.async(flags: .barrier) {
                let subject = self.unsafeSubject(for: key)
                if let newValue = newValue {
                    self.cache[key] = newValue
                    subject.send(newValue)
                } else {
                    self.cache.removeValue(forKey: key)
                    subject.send(nil)
                }
            }
        }
    }
    
    func publisher(forKey key: Key) -> AnyPublisher<Value?, Never> {
        queue.sync(flags: .barrier) {
            unsafeSubject(for: key).eraseToAnyPublisher()
        }
    }
    
    private func unsafeSubject(for key: Key) -> CurrentValueSubject<Value?, Never> {
        if let subject = self.subjects[key] {
            return subject
        } else {
            self.subjects[key] = .init(cache[key])
            return self.subjects[key].unsafelyUnwrapped
        }
    }
}
