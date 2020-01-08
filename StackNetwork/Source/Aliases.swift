//
//  Aliases.swift
//  StackNetwork
//
//  Created by Mai Mai on 1/8/20.
//  Copyright © 2020 maimai. All rights reserved.
//

import Foundation

// MARK: Networks

public typealias NetworkCompletion = (Result<Response, Error>) -> Void

public typealias RequestAdapterClosure = (URLRequest) throws -> URLRequest
public typealias RetryBehaviorClosure = (Request, Error) -> RetryBehavior
public typealias StubBehaviorClosure<Target: TargetType> = (Target) -> StubBehavior

// MARK: Misc
public typealias Second = TimeInterval
public typealias JSON = Any
