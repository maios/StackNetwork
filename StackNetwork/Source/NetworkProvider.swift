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
    private let stubBehavior: StubBehaviorClosure

    // MARK: Initializations

    /// Creates a new instance of `NetworkProvider`.
    /// - Parameter urlSession: The `URLSession` used to make network request. Default is `URLSession.default`.
    /// - Parameter callbackQueue: The default `DispatchQueue` for network callbacks.
    /// - Parameter requestAdapter: The adapter to modify the network request before it is fired.
    public init(urlSession: URLSession = .shared,
                callbackQueue: DispatchQueue? = nil,
                requestAdapter: @escaping RequestAdapterClosure = NetworkProvider.defaultRequestAdapter(_:),
                stubBehavior: @escaping StubBehaviorClosure = NetworkProvider.defaultStubBehavior(_:)) {
        self.urlSession = urlSession
        self.callbackQueue = callbackQueue ?? .main
        self.requestAdapter = requestAdapter
        self.stubBehavior = stubBehavior
    }

    // MARK: NetworkProviderType

    /// Sends network request with given target. Returns a cancellable token which can be used to cancel the request.
    ///
    /// - Parameter target: The target to which the network request will be made and sent.
    /// - Parameter callbackQueue: The `DispatchQueue` on which the callback will be triggered.
    /// If none specified, the default  `callbackQueue` will be used.
    /// - Parameter completion: The callback to trigger when a request is completed.
    public func request(_ target: Target,
                        callbackQueue: DispatchQueue? = nil,
                        completion: @escaping NetworkCompletion) -> Cancellable {

        let callbackQueue = callbackQueue ?? self.callbackQueue
        func complete(withResult result: Result<Response, Error>) {
            callbackQueue.async {
                completion(result)
            }
        }

        do {
            let urlRequest = try requestAdapter(try makeURLRequest(for: target))
            let stubBehavior = self.stubBehavior(target)
            return request(urlRequest,
                           stubBehavior: stubBehavior,
                           callbackQueue: callbackQueue,
                           completion: complete(withResult:))
        } catch {
            complete(withResult: .failure(error))
            return AnyCancellable()
        }
    }

    // MARK: Helpers

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
    public typealias StubBehaviorClosure = (Target) -> StubBehavior
}

// MARK: Internals

extension NetworkProvider {

    private func request(_ urlRequest: URLRequest,
                         stubBehavior: StubBehavior,
                         callbackQueue: DispatchQueue,
                         completion: @escaping NetworkCompletion) -> Cancellable {
        switch stubBehavior {
        case .never:
            return request(urlRequest, callbackQueue: callbackQueue, completion: completion)
        case .immediate(let sampleResponse):
            return stubRequest(urlRequest,
                               sampleResponse: sampleResponse,
                               delay: 0,
                               callbackQueue: callbackQueue,
                               completion: completion)
        case .delay(let seconds, let sampleResponse):
            return stubRequest(urlRequest,
                               sampleResponse: sampleResponse,
                               delay: seconds,
                               callbackQueue: callbackQueue,
                               completion: completion)
        }
    }

    private func request(_ request: URLRequest,
                         callbackQueue: DispatchQueue,
                         completion: @escaping NetworkCompletion) -> Cancellable {
        let task = urlSession.dataTask(with: request) { (data, urlResponse, error) in
            let result: Result<Response, Error>

            if let data = data, let httpResponse = urlResponse as? HTTPURLResponse {
                let response = Response(data: data,
                                        request: request,
                                        response: httpResponse)
                result = .success(response)
            } else {
                result = .failure(error ?? NetworkError.unknown)
            }
            completion(result)
        }
        task.resume()
        return task
    }

    private func stubRequest(_ request: URLRequest,
                             sampleResponse: SampleResponse,
                             delay: TimeInterval,
                             callbackQueue: DispatchQueue,
                             completion: @escaping NetworkCompletion) -> Cancellable {
        let result: Result<Response, Error>
        switch sampleResponse {
        case .networkResponse(let response, let data):
            let response = Response(data: data, request: request, response: response)
            result = .success(response)

        case .networkError(let nsError):
            result = .failure(nsError)
        }

        callbackQueue.asyncAfter(deadline: .now() + delay) {
            completion(result)
        }

        return AnyCancellable()
    }
}

// MARK: Defaults.

public extension NetworkProvider {

    /// The default adapter for `URLRequest`.
    class func defaultRequestAdapter(_ urlRequest: URLRequest) throws -> URLRequest {
        return urlRequest
    }

    /// The default stub behavior for  `Target`.
    class func defaultStubBehavior(_ target: Target) -> StubBehavior {
        return .never
    }
}
