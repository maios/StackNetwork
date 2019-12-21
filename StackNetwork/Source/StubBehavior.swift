//
//  StubBehavior.swift
//  StackNetwork
//
//  Created by Mai Mai on 12/21/19.
//  Copyright © 2019 maimai. All rights reserved.
//

import Foundation

public enum StubBehavior {
    /// Do not stub responses.
    case never
    /// Stub responses immediately.
    case immediate(SampleResponse)
    /// Stub response after a given delay in seconds.
    /// - Note: `StubBehavior.delay(seconds: 0)` will act similar to `StubBehavior.immediate`
    case delay(seconds: TimeInterval, response: SampleResponse)
}

public enum SampleResponse {
    /// The network returned a response, including status code and data.
    case networkResponse(HTTPURLResponse, Data)
    /// The network failed to send the request, or failed to retrieve a response (eg a timeout).
    case networkError(Error)
}
