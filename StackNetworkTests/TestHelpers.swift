//
//  TestHelpers.swift
//  StackNetworkTests
//
//  Created by Mai Mai on 12/21/19.
//  Copyright © 2019 maimai. All rights reserved.
//

import Foundation
@testable import StackNetwork

// MARK: Mock

enum GitHub {
    case zen
    case userProfile(String)
}

extension GitHub: TargetType {
    var baseURL: URL { return URL(string: "https://api.github.com")! }
    var path: String {
        switch self {
        case .zen:
            return "/zen"
        case .userProfile(let name):
            return "/users/\(name)"
        }
    }

    var method: HTTPMethod { return .get }
    var task: Task { return .requestPlain }
    var headers: [String: String]? { return nil }

    var sampleData: Data {
        switch self {
        case .zen:
            return "Half measures are as bad as nothing at all.".data(using: String.Encoding.utf8)!
        case .userProfile(let name):
            return "{\"login\": \"\(name)\", \"id\": 100}".data(using: String.Encoding.utf8)!
        }
    }
}

extension GitHub: Equatable {
    static func == (lhs: GitHub, rhs: GitHub) -> Bool {
        switch (lhs, rhs) {
        case (.zen, .zen): return true
        case let (.userProfile(username1), .userProfile(username2)): return username1 == username2
        default: return false
        }
    }
}

// MARK: Model

struct Cat: Encodable {
    let name: String
    var isGoodBoi: Bool = true

    enum CodingKeys: String, CodingKey {
        case name
    }

    enum `Error`: Swift.Error {
        case catBeingCat
    }

    func encode(to encoder: Encoder) throws {
        if isGoodBoi {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
        } else {
            throw Error.catBeingCat
        }
    }
}

struct MovieCharacter: Decodable, Equatable {
    let id: String
    let name: String
    let gender: String
    let age: Int
}

// MARK: Helpers

extension Result {

    var isSuccess: Bool {
        do {
            _ = try get()
            return true
        } catch {
            return false
        }
    }
}

enum TestError: Error {
    case some
}

struct TestHelper {

    static func stubSampleResponse(target: GitHub, error: Error? = nil) -> SampleResponse {
        if let error = error {
            return .networkError(error)
        } else {
            let response: HTTPURLResponse
            switch target {
            case .zen:
                response = HTTPURLResponse(url: URL(string: "https://api.github.com/zen")!,
                                           statusCode: 200,
                                           httpVersion: "1.1",
                                           headerFields: nil)!
            case .userProfile(let name):
                response = HTTPURLResponse(url: URL(string: "https://api.github.com/users/\(name)")!,
                statusCode: 200,
                httpVersion: "1.1",
                headerFields: nil)!
            }
            return .networkResponse(response, target.sampleData)
        }
    }

    static func getTestMovie() -> Data {
        let url = Bundle(identifier: "com.maimai.StackNetworkTests")!.url(forResource: "movie", withExtension: "json")!
        return try! Data(contentsOf: url, options: .mappedIfSafe)
    }
}
