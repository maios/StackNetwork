//
//  MultiTarget.swift
//  StackNetwork
//
//  Created by Mai Mai on 1/8/20.
//  Copyright © 2020 maimai. All rights reserved.
//

import Foundation

/// A `TargetType` used to enable `NetworkProvider` to process multiple `TargetType`.
public enum MultiTarget: TargetType {
    
    /// The embedded `TargetType`.
    case target(TargetType)

    /// Initializes a `MultiTarget`.
    public init(_ target: TargetType) {
        self = MultiTarget.target(target)
    }

    /// The embedded target's base `URL`.
    public var path: String {
        return target.path
    }

    /// The baseURL of the embedded target.
    public var baseURL: URL {
        return target.baseURL
    }

    /// The HTTP method of the embedded target.
    public var method: HTTPMethod {
        return target.method
    }

    /// The `Task` of the embedded target.
    public var task: Task {
        return target.task
    }

    /// The headers of the embedded target.
    public var headers: [String: String]? {
        return target.headers
    }

    /// The embedded `TargetType`.
    public var target: TargetType {
        switch self {
        case .target(let target): return target
        }
    }
}
