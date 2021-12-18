//
//  Created by Mai Mai on 2/7/20.
//  Copyright © 2020 maimai. All rights reserved.
//

/// A Network Plugin receives callbacks to perform side effects wherever a request is sent or received.
///
/// For example, a plugin may be used to
/// - log network requests
/// - hide and show a network activity indicator
public protocol PluginType {

    /// Called immediately before a request is sent over the network (or stubbed).
    func willSend(_ request: Requestable)

    /// Called after a response has been received, but before the `NetworkProvider` has invoked its completion handler.
    func didReceive(_ result: Result<Response, Error>, request: Requestable)
}
