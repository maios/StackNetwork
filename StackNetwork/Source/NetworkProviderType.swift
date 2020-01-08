//
//  NetworkProviderType.swift
//  StackNetwork
//
//  Created by Mai Mai on 12/21/19.
//  Copyright © 2019 maimai. All rights reserved.
//

import Foundation

public protocol NetworkProviderType {
    associatedtype Target: TargetType

    /// Designated request-making method.
    /// - Returns: A `Cancellable` token that can be used to cancel the network request.
    func request(_ target: Target,
                 callbackQueue: DispatchQueue?,
                 completion: @escaping NetworkCompletion) -> Cancellable
}
