//
//  RateLimiter.swift
//  OpenHaystack
//
//  Created by Rodrigo Kreutz on 22/11/24.
//

import Foundation
import Combine

final class RateLimiter<Key: Hashable> {
    struct Config {
        var concurrentLimit: Int
        var intervalLimit: Int
        var interval: DispatchTimeInterval
    }
    
    private struct Entry {
        var createdAt: Date
        var concurrentRequestsLeft: Int
        var intervalRequestsLeft: Int
    }
    
    private let config: Config
    private let cache: MemoryCache<Key, Entry> = .init()
    private let queue = DispatchQueue(label: "com.rkreutz.RateLimiter")
    
    init(config: Config) {
        self.config = config
    }
    
    func throttle<P: Publisher>(withKey key: Key, publisher: @escaping @autoclosure () -> P) -> AnyPublisher<P.Output, P.Failure> {
        return Deferred {
            var entry = self.cache[key]
                ?? Entry(
                    createdAt: Date(),
                    concurrentRequestsLeft: self.config.concurrentLimit,
                    intervalRequestsLeft: self.config.intervalLimit
                )
            
            guard entry.concurrentRequestsLeft > 0 else {
                return self.cache.publisher(forKey: key)
                    .receive(on: self.queue)
                    .compactMap { entry -> AnyPublisher<P.Output, P.Failure>? in
                        if let entry,
                           entry.concurrentRequestsLeft <= 0 {
                            return nil
                        } else {
                            return self.throttle(withKey: key, publisher: publisher())
                        }
                    }
                    .prefix(1)
                    .switchToLatest()
                    .eraseToAnyPublisher()
            }
            
            guard entry.intervalRequestsLeft > 0 else {
                let retryInterval = (entry.createdAt.timeIntervalSince1970 + self.config.interval.timeInterval - Date().timeIntervalSince1970)
                if retryInterval <= 0 {
                    self.cache[key]?.createdAt = Date()
                    self.cache[key]?.intervalRequestsLeft = self.config.intervalLimit
                    return self.throttle(withKey: key, publisher: publisher())
                } else {
                    return Just<Void>(())
                        .delay(for: .init(DispatchTimeInterval(retryInterval)), scheduler: self.queue)
                        .flatMap { self.throttle(withKey: key, publisher: publisher()) }
                        .eraseToAnyPublisher()
                }
            }
            
            entry.concurrentRequestsLeft -= 1
            entry.intervalRequestsLeft -= 1
            self.cache[key] = entry
            return publisher()
                .handleEvents(
                    receiveCompletion: { _ in
                        self.queue.async {
                            self.cache[key]?.concurrentRequestsLeft += 1
                        }
                    },
                    receiveCancel: {
                        self.queue.async {
                            self.cache[key]?.concurrentRequestsLeft += 1
                        }
                    }
                )
                .eraseToAnyPublisher()
        }
        .subscribe(on: queue)
        .eraseToAnyPublisher()
    }
}

private extension DispatchTimeInterval {
    init(_ timeInterval: TimeInterval) {
        if timeInterval.isNaN || timeInterval.isSignalingNaN || timeInterval.isInfinite {
            self = .never
        } else {
            self = .seconds(Int(ceil(timeInterval)))
        }
    }
    
    var timeInterval: TimeInterval {
        switch self {
        case let .nanoseconds(value):
            return TimeInterval(value) / 10e9
        case let .microseconds(value):
            return TimeInterval(value) / 10e6
        case let .milliseconds(value):
            return TimeInterval(value) / 10e3
        case let .seconds(value):
            return TimeInterval(value)
        case .never:
            return .infinity
        @unknown default:
            return .infinity
        }
    }
}
