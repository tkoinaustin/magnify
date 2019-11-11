//
//  DeferredPromise.swift
//
//  Copyright © 2018 InMotion Software. All rights reserved.
//

import Foundation
import PromiseKit

public class DeferredPromise<T> {
    
    public private(set) var promise: Promise<T>!
    fileprivate var resolver: Resolver<T>!
    
    convenience public init() {
        self.init(initializer: nil)
    }
    
    public init(initializer: (() throws -> Void)? ) {
        self.resolver = nil
        self.promise = Promise { resolver in
            self.resolver = resolver

            if let initializer = initializer {
                try initializer()
            }
        }
    }
    
    public func resolve(_ value: T ) -> Swift.Void {
        self.resolver.fulfill(value)
    }
    
    public func reject(_ error: Error) -> Swift.Void {
        self.resolver.reject(error)
    }
}
