//
//  RequestEncoding.swift
//  StackNetwork
//
//  Created by Mai Mai on 12/21/19.
//  Copyright © 2019 maimai. All rights reserved.
//

import Foundation

public protocol URLRequestEncoderType {
    associatedtype EncodableType
    /// Creates a URL request by encoding parameters and applying them onto an existing request.
    ///
    /// - parameter urlRequest: The request to have encodable value applied.
    /// - parameter encodable: The encodable value to apply.
    ///
    /// - throws: An `URLEncodingError` error if encoding fails.
    ///
    /// - returns: The encoded request.
    func encode(_ urlRequest: URLRequest, with encodable: EncodableType) throws -> URLRequest
}

public enum URLRequestEncodingError: Error {
    case missingURL
    case invalidURL
    case encodingFailed(underlyingError: EncodingError)
}
