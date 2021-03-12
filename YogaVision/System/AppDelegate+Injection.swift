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
    register {
      PoseRecognizer()
    }
    .scope(.application)
    register {
      VideoRecognizer()
    }
    .scope(.application)
    register {
      MLInfo()
    }
    .scope(.application)
  }
}
