//
//  AppDelegate+Injection.swift
//  YogaVision
//
//  Created by Mayank Gandhi on 3/9/21.
//

import Foundation
import Resolver

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        register { LiveRecognizer() }
            .scope(.shared)
        register { VideoRecognizer() }
            .scope(.shared)
        register { MLInfo() }
            .scope(.application)
    }
}
