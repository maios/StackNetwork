//
//  Task.swift
//  StackNetwork
//
//  Created by Mai Mai on 12/21/19.
//  Copyright © 2019 maimai. All rights reserved.
//

import Foundation

/// Represents an HTTP task.
public enum Task {
    /// A request with no additional data.
    case requestPlain

    /// A requests body set with data.
    case requestData(Data)

    /// A request body set with `Encodable` type.
    case requestEncodable(Encodable)

    /// A request body set with `Encodable` type and a custom encoder.
    case requestEncodable(Encodable, encoder: JSONEncoder)

    /// A requests body set with encoded parameters.
    case requestParameters([String: Any])

    /// A requests body set with encoded parameters and a custom encoder.
    case requestParameters([String: Any], encoder: ParameterEncoder)
}
