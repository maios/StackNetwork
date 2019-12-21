//
//  Cancellable.swift
//  StackNetwork
//
//  Created by Mai Mai on 12/21/19.
//  Copyright © 2019 maimai. All rights reserved.
//

import Foundation

/// Protocol to define the opaque type returned from a request.
public protocol Cancellable {
    /// A Boolean value stating whether a request is cancelled.
    var isCancelled: Bool { get }

    /// Cancels the represented request.
    func cancel()
}

extension URLSessionDataTask: Cancellable {

    public var isCancelled: Bool {
        return state == .canceling
    }
}

internal class AnyCancellable: Cancellable {
    var isCancelled = false

    func cancel() {
        isCancelled = true
    }
}
