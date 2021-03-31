//
//  ContentView.swift
//  YogaVision
//
//  Created by Mayank Gandhi on 3/9/21.
//

import Resolver
import SwiftUI

struct ContentView: View {
  @Injected var videoRecognizer: VideoRecognizer
  @InjectedObject var mlInfo: MLInfo
  @State var showGallery: Bool = false
  @State var url = URL(fileURLWithPath: "www.google.com")

  var plusButton: some View {
    Button {
      self.showGallery = true
    } label: {
      Image(systemName: "plus")
    }
  }

  var progressView: some View {
    ProgressView(mlInfo.progress > 50 ? "Performing prediction..." : "Gathering Data...", value: mlInfo.progress, total: 100)
      .frame(width: 200, alignment: .center)
  }

  var poseText: some View {
    VStack(alignment: .center, spacing: 20) {
      if mlInfo.mountainPose + mlInfo.plank > 0 {
        Text("\(mlInfo.plank > mlInfo.mountainPose ? "Plank" : "Mountain Pose")")
          .font(.headline)
      }
    }
  }

  var videoRecognizerView: some View {
    VStack(alignment: .center, spacing: 20) {
      if mlInfo.loading {
        VideoPlayer(videoURL: url)
          .frame(width: 200, height: 400, alignment: .center)
        progressView
      } else {
        plusButton
      }

      if mlInfo.show {
        poseText
          .padding(.all, 30)
          .background(Color.gray.opacity(0.5))
          .cornerRadius(20)
          .padding()
      }
    }
  }

  var recognisedPoseView: some View {
    VStack(alignment: .center, spacing: 20) {
      progressView
      poseText
    }
    .padding(.all, 30)
    .background(Color.gray.opacity(0.5))
    .cornerRadius(20)
    .padding()
  }

  var liveRecognizerView: some View {
    ZStack(alignment: .center) {
      LiveRecognizerViewController.LiveRecognizerViewRepresentable()
        .edgesIgnoringSafeArea(.top)
      VStack {
        Spacer()
        recognisedPoseView
      }
    }
  }

  var body: some View {
    NavigationView {
      TabView {
        videoRecognizerView
          .onAppear(perform: mlInfo.reset)
          .tabItem {
            Label("Video", systemImage: "video.fill")
          }

        liveRecognizerView
          .onAppear(perform: mlInfo.reset)
          .tabItem {
            Label("Live", systemImage: "livephoto")
          }
      }
    }
    .sheet(isPresented: $showGallery) {
      VideoPicker(showVideoPicker: $showGallery, videoURL: $url)
        .ignoresSafeArea()
    }
  }
}
