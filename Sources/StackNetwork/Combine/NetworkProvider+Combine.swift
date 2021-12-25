import Foundation
import UIKit

#if canImport(Combine)
import Combine

@available(iOS 13.0, *)
extension NetworkProvider {

    /// Retuns a publisher to execute a network-request with given target.
    public func requestPublisher(_ target: Target, callbackQueue: DispatchQueue? = nil) -> AnyPublisher<Response, Error> {
        var requestToken: StackNetwork.Cancellable?
        return Deferred {
            Future<Response, Error> { promise in
                requestToken = self.request(target, callbackQueue: callbackQueue, completion: promise)
            }
            .handleEvents(
                receiveCancel: {
                    requestToken?.cancel()
                }
            )
        }
        .eraseToAnyPublisher()
    }
}

@available(iOS 13.0, *)
extension Publisher where Output == StackNetwork.Response {

    /// Maps response' data into a Decodable object.
    public func map<D: Decodable>(
        _ type: D.Type,
        atKeyPath path: String? = nil,
        using decoder: JSONDecoder = JSONDecoder(),
        failsOnEmptyData: Bool = true)
    -> AnyPublisher<D, Error> {

        tryMap {
            try $0.map(D.self, atKeyPath: path, using: decoder, failsOnEmptyData: failsOnEmptyData)
        }
        .eraseToAnyPublisher()
    }

    /// Maps response's data into a JSON object.
    public func mapJSON(failsOnEmptyData: Bool = true) -> AnyPublisher<JSON, Error> {
        tryMap {
            try $0.mapJSON(failsOnEmptyData: failsOnEmptyData)
        }
        .eraseToAnyPublisher()
    }

    /// Maps response's data into an image.
    public func mapImage() -> AnyPublisher<UIImage, Error> {
        tryMap {
            try $0.mapImage()
        }
        .eraseToAnyPublisher()
    }
}

@available(iOS 13.0, *)
extension Publisher where Output == StackNetwork.Response {

    /// Filters out response with status code that falls within the given range.
    public func filter<R: RangeExpression>(statusCodes: R) -> AnyPublisher<Response, Error> where R.Bound == Int {
        tryMap {
            try $0.filter(statusCodes: statusCodes)
        }
        .eraseToAnyPublisher()
    }

    /// Filters out response with status code that matches the given code.
    public func filter(statusCode: Int) -> AnyPublisher<Response, Error> {
        filter(statusCodes: statusCode...statusCode)
    }

    /// Filters out response with successful status codes, range 200 - 299.
    public func filterSuccessfulStatusCodes() -> AnyPublisher<Response, Error> {
        filter(statusCodes: 200...299)
    }

    /// Filters out response with successful and redirect status codes, range 200 - 399.
    public func filterSuccessfulStatusAndRedirectCodes() -> AnyPublisher<Response, Error> {
        filter(statusCodes: 200...399)
    }
}
#endif
