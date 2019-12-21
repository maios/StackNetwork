//
//  ParameterEncoder.swift
//  StackNetwork
//
//  Created by Mai Mai on 12/21/19.
//  Copyright © 2019 maimai. All rights reserved.
//

import Foundation

public struct ParameterEncoder: URLRequestEncoderType {
    typealias EncodingType = [String: Any]

    // MARK: - Helper Types

    /// Defines whether the url-encoded query string is applied to the existing query string or HTTP body
    /// of the resulting URL request.
    public enum Destination {
        /// Applies encoded query string result to existing query string for `GET`, `HEAD` and `DELETE`
        /// requests and sets as the HTTP body for requests with any other HTTP method.
        case methodDependent
        /// Sets or appends encoded query string result to existing query string.
        case queryString
        ///  Sets encoded query string result as the HTTP body of the URL request.
        case httpBody

        func encodesParametersInURL(for method: HTTPMethod) -> Bool {
            switch self {
            case .methodDependent: return [.get, .head, .delete].contains(method)
            case .queryString:     return true
            case .httpBody:        return false
            }
        }
    }

    /// Configures how `Array` parameters are encoded.
    public enum ArrayEncoding {
        /// An empty set of square brackets is appended to the key for every value. This is the default behavior.
        case brackets
        /// No brackets are appended. The key is encoded as is.
        case noBrackets

        func encode(key: String) -> String {
            switch self {
            case .brackets:
                return "\(key)[]"
            case .noBrackets:
                return key
            }
        }
    }

    /// Configures how `Bool` parameters are encoded.
    public enum BoolEncoding {
        /// Encode `true` as `1` and `false` as `0`. This is the default behavior.
        case numeric
        /// Encode `true` and `false` as string literals.
        case literal

        func encode(value: Bool) -> String {
            switch self {
            case .numeric:
                return value ? "1" : "0"
            case .literal:
                return value ? "true" : "false"
            }
        }
    }

    // MARK: - Conveniences

    /// Returns a default `URLEncoding` instance with a `.methodDependent` destination.
    public static let `default` = ParameterEncoder()

    /// Returns a `URLEncoding` instance with a `.queryString` destination.
    public static let queryString = ParameterEncoder(destination: .queryString)

    /// Returns a `URLEncoding` instance with an `.httpBody` destination.
    public static let httpBody = ParameterEncoder(destination: .httpBody)

    // MARK: Properties

    /// The destination defining where the encoded query string is to be applied to the URL request.
    public let destination: Destination

    /// The encoding to use for `Array` parameters.
    public let arrayEncoding: ArrayEncoding

    /// The encoding to use for `Bool` parameters.
    public let boolEncoding: BoolEncoding

    // MARK: - Initialization

    /// Creates a `URLEncoding` instance using the specified destination.
    ///
    /// - parameter destination: The destination defining where the encoded query string is to be applied.
    /// - parameter arrayEncoding: The encoding to use for `Array` parameters.
    /// - parameter boolEncoding: The encoding to use for `Bool` parameters.
    ///
    /// - returns: The new `URLEncoding` instance.
    public init(destination: Destination = .methodDependent,
                arrayEncoding: ArrayEncoding = .brackets,
                boolEncoding: BoolEncoding = .numeric) {
        self.destination = destination
        self.arrayEncoding = arrayEncoding
        self.boolEncoding = boolEncoding
    }

    // MARK: - Encoding

    /// Creates a URL request by encoding parameters and applying them onto an existing request.
    ///
    /// - parameter urlRequest: The request to have parameters applied.
    /// - parameter parameters: The parameters to apply.
    ///
    /// - throws: An `Error` if the encoding process encounters an error.
    ///
    /// - returns: The encoded request.
    public func encode(_ urlRequest: URLRequest, with value: [String : Any]?) throws -> URLRequest {
        var urlRequest = urlRequest

        guard let parameters = value, !parameters.isEmpty else {
            return urlRequest
        }

        guard let url = urlRequest.url else {
            throw URLRequestEncodingError.missingURL
        }

        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw URLRequestEncodingError.invalidURL
        }

        var queryItems = urlComponents.queryItems ?? []
        queryItems += parameters.flatMap(makeQueryItems(for:value:))
        let query = queryItems
            .map { $0.description }
            .joined(separator: "&")

        if let httpMethod = HTTPMethod(rawValue: urlRequest.httpMethod ?? "GET"),
            destination.encodesParametersInURL(for: httpMethod) {
            urlComponents.percentEncodedQuery = query
            urlRequest.url = urlComponents.url
        } else {
            urlRequest.httpBody = query.data(using: .utf8, allowLossyConversion: false)

            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.addValue("application/x-www-form-urlencoded; charset=utf-8",
                                    forHTTPHeaderField: "Content-Type")
            }
        }

        return urlRequest
    }

    /// Creates percent-escaped, URL encoded query string components from the given key-value pair using recursion.
    ///
    /// - parameter key:   The key of the query component.
    /// - parameter value: The value of the query component.
    ///
    /// - returns: The percent-escaped, URL encoded query string components.
    private func makeQueryItems(for key: String, value: Any) -> [URLQueryItem] {
        var queryItems: [URLQueryItem] = []
        if let dictionary = value as? EncodingType {
            return dictionary.reduce(into: queryItems) { (result, item) in
                result += self.makeQueryItems(for: "\(key)[\(item.key)]", value: item.value)
            }
        } else if let array = value as? [Any] {
            queryItems += array.flatMap { self.makeQueryItems(for: arrayEncoding.encode(key: key), value: $0) }
        } else if let number = value as? NSNumber {
            if number.isBool {
                queryItems.append(.init(name: escape(key), value: boolEncoding.encode(value: number.boolValue)))
            } else {
                queryItems.append(.init(name: escape(key), value: escape("\(value)")))
            }
        } else if let boolValue = value as? Bool {
            queryItems.append(.init(name: escape(key), value: escape(boolEncoding.encode(value: boolValue))))
        } else {
            queryItems.append(.init(name: escape(key), value: escape("\(value)")))
        }
        return queryItems
    }

    /// Returns a percent-escaped string following RFC 3986 for a query string key or value.
    ///
    /// RFC 3986 states that the following characters are "reserved" characters.
    ///
    /// - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
    /// - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="
    ///
    /// In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
    /// query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
    /// should be percent-escaped in the query string.
    ///
    /// - parameter string: The string to be percent-escaped.
    ///
    /// - returns: The percent-escaped string.
    private func escape(_ string: String) -> String {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")

        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
    }
}

// MARK - Private

private extension NSNumber {

    var isBool: Bool {
        return CFBooleanGetTypeID() == CFGetTypeID(self)
    }
}
