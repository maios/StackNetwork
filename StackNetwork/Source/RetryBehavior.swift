//
//  RetryBehavior.swift
//  StackNetwork
//
//  Created by Mai Mai on 1/8/20.
//  Copyright © 2020 maimai. All rights reserved.
//

import Foundation

public enum RetryBehavior {
    /// Do not retry.
    case doNotRetry
    /// Retry immediately.
    case immediate
    /// Retry after a given delay in seconds.
    case retryWithDelay(Second)
}

internal extension RetryBehavior {

    /// A Boolean value determines whether a receiver should retry.
    var shouldRetry: Bool {
        switch self {
        case .doNotRetry: return false
        case .immediate, .retryWithDelay: return true
        }
    }

    /// Determines when the next retry will be fired.
    var delayInterval: Second {
        switch self {
        case .doNotRetry: return .nan
        case .immediate: return .zero
        case .retryWithDelay(let interval): return interval
        }
    }
}
