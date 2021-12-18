//
//  Response+Filter.swift
//  StackNetwork
//
//  Created by Mai Mai on 12/22/19.
//  Copyright © 2019 maimai. All rights reserved.
//

import Foundation

extension Response {

    /// Returns the `Response` if the `statusCode` falls within the specified range.
    ///
    /// - Parameter statusCodes: The range of acceptable status codes.
    /// - Throws: `NetworkProvider.statusCode` if the status code does not match.
    public func filter<R: RangeExpression>(statusCodes: R) throws -> Response where R.Bound == Int {
        guard statusCodes.contains(statusCode) else {
            throw NetworkError.statusCode(self)
        }
        return self
    }

    /// Returns the `Response` if the `statusCode` match the given code.
    ///
    /// - Parameter statusCode: The acceptable status code.
    /// - Throws: `NetworkProvider.statusCode` if the status code does not match.
    public func filter(statusCode: Int) throws -> Response {
        return try filter(statusCodes: statusCode...statusCode)
    }

    /// Returns the `Response` if status code falls within range 200-299.
    ///
    /// - Throws: `NetworkProvider.statusCode` if the status code does not match.
    public func filterSuccessfulStatusCodes() throws -> Response {
        return try filter(statusCodes: 200...299)
    }

    /// Returns the `Response` if status code falls within range 200-399
    /// 
    /// - Throws: `NetworkProvider.statusCode` if the status code does not match.
    public func filterSuccessfulStatusAndRedirectCodes() throws -> Response {
        return try filter(statusCodes: 200...399)
    }
}
