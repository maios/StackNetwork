//
//  Response+Map.swift
//  StackNetwork
//
//  Created by Mai Mai on 12/22/19.
//  Copyright © 2019 maimai. All rights reserved.
//

import UIKit

extension Response {

    public enum `Error`: Swift.Error {
        case imageMappingFailed(Response)
        case stringMappingFailed(Response)
        case jsonMappingFailed(Response, Swift.Error)
        case decodingFailed(Response, Swift.Error)
    }

    public func mapImage() throws -> UIImage {
        guard let image = UIImage(data: data) else {
            throw Error.imageMappingFailed(self)
        }
        return image
    }

    public func mapJSON(failsOnEmptyData: Bool = true) throws -> JSON {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        } catch {
            if data.count < 1 && !failsOnEmptyData {
                return NSNull()
            }
            throw Error.jsonMappingFailed(self, error)
        }
    }

    public func map<D: Decodable>(_ type: D.Type,
                                  atKeyPath keyPath: String? = nil,
                                  using decoder: JSONDecoder = JSONDecoder(),
                                  failsOnEmptyData: Bool = true) throws -> D {
        do {
            return try decoder.decode(type, from: data, atKeyPath: keyPath, failsOnEmptyData: failsOnEmptyData)
        } catch {
            throw Error.decodingFailed(self, error)
        }
    }

    public func mapString(atKeyPath keyPath: String? = nil) throws -> String {
        return try map(String.self, atKeyPath: keyPath)
    }
}
