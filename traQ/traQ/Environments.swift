//
//  Environments.swift
//  traQ
//
//  Created by spa on 2021/01/21.
//

import SwiftUI

struct HostKey: EnvironmentKey {
    static var defaultValue: String {
        return traQConstants.defaultHost
    }
}

extension EnvironmentValues {
    var host: String {
        get { self[HostKey.self] }
        set { self[HostKey.self] = newValue }
    }
}
