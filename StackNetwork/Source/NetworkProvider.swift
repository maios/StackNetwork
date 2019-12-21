//
//  NetworkProvider.swift
//  StackNetwork
//
//  Created by Mai Mai on 12/21/19.
//  Copyright © 2019 maimai. All rights reserved.
//

import Foundation

/// The network request provider. All network requests should be made using this class only.
open class NetworkProvider<Target: TargetType>: NetworkProviderType {

    private let urlSession: URLSession
    private let callbackQueue: DispatchQueue

    private let requestAdapter: RequestAdapterClosure

    // MARK: Initializations

    /// Creates a new instance of `NetworkProvider`.
    /// - Parameter urlSession: The `URLSession` used to make network request. Default is `URLSession.default`.
    /// - Parameter callbackQueue: The default `DispatchQueue` for network callbacks.
    /// - Parameter requestAdapter: The adapter to modify the network request before it is fired.
    public init(urlSession: URLSession = .shared,
                callbackQueue: DispatchQueue? = nil,
                requestAdapter: @escaping RequestAdapterClosure) {
        self.urlSession = urlSession
        self.callbackQueue = callbackQueue ?? .main
        self.requestAdapter = requestAdapter
    }

    // MARK: NetworkProviderType

    public func request(_ target: Target,
                        callbackQueue: DispatchQueue?,
                        completion: @escaping NetworkCompletion) -> Cancellable {

        let callbackQueue = callbackQueue ?? self.callbackQueue
        func complete(withResult result: Result<Response, Error>) {
            callbackQueue.async {
                completion(result)
            }
        }

        do {
            let request = try requestAdapter(try makeURLRequest(for: target))
            let task = urlSession.dataTask(with: request) { (data, urlResponse, error) in
                let result: Result<Response, Error>

                if let data = data, let httpResponse = urlResponse as? HTTPURLResponse {
                    let response = Response(statusCode: httpResponse.statusCode,
                                            data: data,
                                            request: nil,
                                            response: httpResponse)
                    result = .success(response)
                } else {
                    result = .failure(error ?? NetworkError.unknown)
                }
                complete(withResult: result)
            }
            task.resume()
            return task
        } catch {
            complete(withResult: .failure(error))
            return AnyCancellable()
        }
    }

    private func makeURLRequest(for target: Target) throws -> URLRequest {
        var requestURL = target.baseURL

        if !target.path.isEmpty {
            requestURL.appendPathComponent(target.path)
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = target.method.rawValue
        target.headers?.forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }

        switch target.task {
        case .requestPlain: break
        case .requestData(let data): request.httpBody = data
        case .requestEncodable(let encodable):
            try encode(request: &request, with: encodable.0, using: encodable.encoder)
        case .requestParameters(let encodable):
            try encode(request: &request, with: encodable.0, using: encodable.encoder)
        }

        return request
    }

    private func encode<E: URLRequestEncoderType>(request: inout URLRequest,
                                                  with encodable: E.EncodableType,
                                                  using encoder: E) throws {
        request = try encoder.encode(request, with: encodable)
    }

    // MARK: - Closures

    public typealias RequestAdapterClosure = (URLRequest) throws -> URLRequest
}
