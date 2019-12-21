//
//  Error.swift
//  StackNetwork
//
//  Created by Mai Mai on 12/21/19.
//  Copyright © 2019 maimai. All rights reserved.
//

import Foundation

public enum NetworkError: Error {
    /// Request failed because of unknown error.
    case unknown
    /// Request failed because of network error.
    case requestFailed(Error, Data?)
    /// Others.
    case others(Error)
}
