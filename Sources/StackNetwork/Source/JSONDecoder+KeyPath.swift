//
//  JSONDecoder+KeyPath.swift
//  StackNetwork
//
//  Created by Mai Mai on 12/22/19.
//  Copyright © 2019 maimai. All rights reserved.
//

import Foundation

private struct DecodableWrapper<T>: Decodable where T: Decodable {
    let value: T
}

extension JSONDecoder {

    /// Decodes a nested-level value of the given type and key path from the given JSON representation.
    ///
    /// - Parameter type: The type of the value to decode.
    /// - Parameter data: The data to decode from.
    /// - Parameter keyPath: The key path to decode at (can be nested)
    /// - Parameter options: The set of `JSONSerialization.ReadingOptions` used to read from given data.
    /// - Parameter failsOnEmptyData: If `true`, decoder will immediately throw exception if an empty data is encountered.
    /// - Returns: A value of the requested type.
    /// - Throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted, or if the given data is not valid JSON.
    /// - Throws: An error if any value throws an error during decoding.
    func decode<T>(_ type: T.Type,
                   from data: Data,
                   atKeyPath keyPath: String? = nil,
                   options: JSONSerialization.ReadingOptions = .fragmentsAllowed,
                   failsOnEmptyData: Bool = true) throws -> T where T : Decodable {

        let serializeToData: (Any) throws -> Data? = { jsonObject in
            guard JSONSerialization.isValidJSONObject(jsonObject) else {
                return nil
            }
            return try JSONSerialization.data(withJSONObject: jsonObject)
        }

        let topLevel: JSON
        do {
            topLevel = try JSONSerialization.jsonObject(with: data, options: options)
        } catch {
            if !failsOnEmptyData {
                topLevel = NSNull()
            } else {
                throw error
            }
        }

        let keyPaths = keyPath?.components(separatedBy: ".").filter { !$0.isEmpty } ?? []

        if keyPaths.isEmpty {
            return try decode(type, from: data)
        }

        if let _keyPath = keyPaths.first, let nestedJSON = (topLevel as AnyObject).value(forKeyPath: _keyPath) {
            let remainingKeyPaths = keyPaths.dropFirst()

            if let nestedData = try serializeToData(nestedJSON) {
                return try decode(type,
                                  from: nestedData,
                                  atKeyPath: remainingKeyPaths.joined(separator: "."),
                                  failsOnEmptyData: failsOnEmptyData)
            } else {
                let wrappedJSON = ["value": nestedJSON]
                if let wrappedData = try serializeToData(wrappedJSON) {
                    return try decode(DecodableWrapper<T>.self,
                                      from: wrappedData,
                                      atKeyPath: remainingKeyPaths.joined(separator: "."),
                                      failsOnEmptyData: failsOnEmptyData).value
                } else {
                    throw DecodingError.dataCorrupted(.init(codingPath: [],
                                                            debugDescription: "Failed to serialize JSON to Data at key path \(keyPath!)"))
                }
            }
        } else if !failsOnEmptyData, let emptyValue = decodeEmptyData(type) {
            return emptyValue
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: [],
                                                    debugDescription: "Nested JSON not found at key path \(keyPath!)"))
        }
    }

    private func decodeEmptyData<T: Decodable>(_ type: T.Type) -> T? {
        return ["{}", "[]"]
            .compactMap { $0.data(using: .utf8) }
            .compactMap { [unowned self] data -> T? in
                do {
                    return try self.decode(type, from: data)
                } catch {
                    return nil
                }
            }.first
    }
}
