//
//  Task.swift
//  StackNetwork
//
//  Created by Mai Mai on 12/21/19.
//  Copyright © 2019 maimai. All rights reserved.
//

/// Represents an HTTP task.
public enum Task {
    /// A request with no additional data.
    case requestPlain

    /// A requests body set with data.
    case requestData(Data)
}
