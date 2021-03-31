//
//  MLInfo.swift
//  YogaVision
//
//  Created by Mayank Gandhi on 3/12/21.
//

import Foundation
import SwiftUI

class MLInfo: ObservableObject {
    @Published var show: Bool = false
    @Published var progress: Float = 0

    @Published var mountainPose: Float = 0.0
    @Published var plank: Float = 0.0
}
