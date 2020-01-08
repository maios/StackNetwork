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
    private let retryBehavior: RetryBehaviorClosure
    private let stubBehavior: StubBehaviorClosure<Target>

    // MARK: Initializations

    /// Creates a new instance of `NetworkProvider`.
    /// - Parameter urlSession: The `URLSession` used to make network request. Default is `URLSession.default`.
    /// - Parameter callbackQueue: The default `DispatchQueue` for network callbacks.
    /// - Parameter requestAdapter: The adapter to modify the network request before it is fired.
    /// - Parameter retryBehavior: The retry behavior when a network request fails.
    /// - Parameter stubBehavior: Decides if a network response will be stubbed.
    public init(urlSession: URLSession = .shared,
                callbackQueue: DispatchQueue? = nil,
                requestAdapter: @escaping RequestAdapterClosure = NetworkProvider.defaultRequestAdapter(_:),
                retryBehavior: @escaping RetryBehaviorClosure = NetworkProvider.defaultRequestBehavior(_:error:),
                stubBehavior: @escaping StubBehaviorClosure<Target> = NetworkProvider.defaultStubBehavior(_:)) {
        self.urlSession = urlSession
        self.callbackQueue = callbackQueue ?? .main
        self.requestAdapter = requestAdapter
        self.retryBehavior = retryBehavior
        self.stubBehavior = stubBehavior
    }

    // MARK: NetworkProviderType

    /// Sends network request with given target. Returns a cancellable token which can be used to cancel the request.
    ///
    /// - Parameter target: The target to which the network request will be made and sent.
    /// - Parameter callbackQueue:
    ///     The **DispatchQueue** on which the callback will be triggered.
    ///     If none specified, the default  `callbackQueue` will be used.
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
            let request = Request(urlRequest: try makeURLRequest(for: target))
            let stubBehavior = self.stubBehavior(target)
            return self.request(request,
                                stubBehavior: stubBehavior,
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
}

// MARK: Internals

extension NetworkProvider {

    /// Attempts to retry the given `Request` with the given `result`.
    private func retry(request: Request,
                       with result: Result<Response, Error>,
                       stubBehavior: StubBehavior,
                       completion: @escaping NetworkCompletion) {
        let retryBehavior: RetryBehavior
        if case .failure(let error) = result {
            retryBehavior = self.retryBehavior(request, error)
        } else {
            retryBehavior = .doNotRetry
        }

        if retryBehavior.shouldRetry {
            request.retryCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + retryBehavior.delayInterval) {
                _ = self.request(request,
                                 stubBehavior: stubBehavior,
                                 completion: completion)
            }
        } else {
            completion(result)
        }
    }

    /// Executes the given **Request** based on the given `stubBehavior`.
    private func request(_ request: Request,
                         stubBehavior: StubBehavior,
                         completion: @escaping NetworkCompletion) -> Cancellable {

        let retryBeforeComplete: NetworkCompletion = { [weak self] result in
            self?.retry(request: request,
                        with: result,
                        stubBehavior: stubBehavior,
                        completion: completion)
        }

        do {
            request.urlRequest = try requestAdapter(request.urlRequest)
            switch stubBehavior {
            case .never:
                return self.request(request, completion: retryBeforeComplete)
            case .immediate(let sampleResponse):
                return stubRequest(request,
                                   sampleResponse: sampleResponse,
                                   delay: 0,
                                   completion: retryBeforeComplete)
            case .delay(let seconds, let sampleResponse):
                return stubRequest(request,
                                   sampleResponse: sampleResponse,
                                   delay: seconds,
                                   completion: retryBeforeComplete)
            }
        } catch {
            retryBeforeComplete(.failure(error))
            return AnyCancellable()
        }
    }

    /// Performs an actual network request for the given **Request**.
    ///
    /// - Parameter request: The **Request** to perform.
    /// - Parameter completion: The callback to be triggered when a network task is completed.
    private func request(_ request: Request, completion: @escaping NetworkCompletion) -> Cancellable {
        let task = urlSession.dataTask(with: request.urlRequest) { (data, urlResponse, error) in
            let result: Result<Response, Error>

            if let data = data, let httpResponse = urlResponse as? HTTPURLResponse {
                let response = Response(data: data,
                                        request: request.urlRequest,
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

    /// Stub network response for the given **Request** and trigger completion.
    ///
    /// - Parameter request: The **Request** to which response will be stubbed.
    /// - Parameter sampleResponse: Decides which response will be stubbed.
    /// - Parameter delay: Decides when the stubbed response will be sent.
    /// - Parameter completion: The callback to receive stubbed response.
    private func stubRequest(_ request: Request,
                             sampleResponse: SampleResponse,
                             delay: TimeInterval,
                             completion: @escaping NetworkCompletion) -> Cancellable {
        let result: Result<Response, Error>
        switch sampleResponse {
        case .networkResponse(let response, let data):
            let response = Response(data: data, request: request.urlRequest, response: response)
            result = .success(response)

        case .networkError(let nsError):
            result = .failure(nsError)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            completion(result)
        }

        return AnyCancellable()
    }
}

// MARK: Default values.

public extension NetworkProvider {

    /// The default adapter for `URLRequest`.
    class func defaultRequestAdapter(_ urlRequest: URLRequest) throws -> URLRequest {
        return urlRequest
    }

    /// The default retry behavior.
    class func defaultRequestBehavior(_ request: Request, error: Error) -> RetryBehavior {
        return .doNotRetry
    }

    /// The default stub behavior for  `Target`.
    class func defaultStubBehavior(_ target: Target) -> StubBehavior {
        return .never
    }
}
