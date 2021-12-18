//
//  JSONEncoder+RequestEncoding.swift
//  StackNetwork
//
//  Created by Mai Mai on 12/21/19.
//  Copyright © 2019 maimai. All rights reserved.
//

import Foundation

extension JSONEncoder: URLRequestEncoderType {
    public typealias EncodableType = Encodable

    public func encode(_ urlRequest: URLRequest, with encodable: Encodable) throws -> URLRequest {
        do {
            var urlRequest = urlRequest
            let encodable = AnyEncodable(encodable: encodable)

            try urlRequest.httpBody = encode(encodable)
            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            }

            return urlRequest
        } catch let encodingError as EncodingError {
            throw URLRequestEncodingError.encodingFailed(underlyingError: encodingError)
        }
    }
}

private struct AnyEncodable: Encodable {
    let encodable: Encodable

    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}
