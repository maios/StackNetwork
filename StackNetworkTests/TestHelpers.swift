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

// MARK: Helpers

struct TestHelper {

    static func stubSuccess(target: GitHub) -> SampleResponse {
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

    static func stubFailure(target: GitHub, error: Error) -> SampleResponse {
        return .networkError(error)
    }
}
