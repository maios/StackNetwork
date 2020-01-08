//
//  Request.swift
//  StackNetwork
//
//  Created by Mai Mai on 1/4/20.
//  Copyright © 2020 maimai. All rights reserved.
//

import Foundation

/// Reifies a target represented by `Target` into a concrete `Request`.
public final class Request {

    /// The internal `URLRequest` of the receiver.
    public internal(set) var urlRequest: URLRequest

    /// Number of times the `Request` has been retried.
    public internal(set) var retryCount: Int {
        get {
            lock.lock()
            let value = _retryCount
            lock.unlock()
            return value
        }
        set {
            lock.lock()
            _retryCount = newValue
            lock.unlock()
        }
    }
    private var _retryCount: Int

    // MARK: Initializations

    internal init(urlRequest: URLRequest) {
        self.urlRequest = urlRequest
        self._retryCount = 0
    }

    // MARK: Private

    private let lock = NSLock()
}
