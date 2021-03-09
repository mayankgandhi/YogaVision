//
//  VideoPlayer.swift
//  DanceVision
//
//  Created by Mayank Gandhi on 11/4/20.
//

import AVFoundation
import AVKit
import Combine
import Foundation
import SwiftUI

struct VideoPlayer: UIViewRepresentable {
    @State var videoURL: URL

    func makeUIView(context _: Context) -> VideoPlayerView {
        return VideoPlayerView(frame: .zero, url: videoURL)
    }

    func updateUIView(_: VideoPlayerView, context _: Context) {
        //
    }
}

class VideoPlayerView: UIView, ObservableObject {
    var started: Bool = false
    let player = AVQueuePlayer()
    private let playerLayer = AVPlayerLayer()
    private var loopPlayer: AVPlayerLooper?
    var videoURL: URL
    var item: AVPlayerItem?

    init(frame: CGRect, url: URL) {
        videoURL = url // has to be before super init
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        player.removeAllItems()
        playerLayer.player = nil
        playerLayer.removeFromSuperlayer()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    func setup() {
        item = AVPlayerItem(url: videoURL)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
        loopPlayer = AVPlayerLooper(player: player, templateItem: item!)
        player.play()
        player.volume = 0
    } // setup
    
}
