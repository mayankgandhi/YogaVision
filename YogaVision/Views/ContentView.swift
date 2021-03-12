//
//  ContentView.swift
//  YogaVision
//
//  Created by Mayank Gandhi on 3/9/21.
//

import SwiftUI
import Resolver

struct ContentView: View {

  @Injected var poseRecognizer: PoseRecognizer
  @State var showGallery: Bool = false
  @State var url: URL = URL(fileURLWithPath: "www.google.com")

  @State var pickerSelection: Int = 1

  var plusButton: some View {
    Button {
      self.showGallery = true
    } label: {
      Image(systemName: "plus")
    }
  }

  var segmentedPicker: some View {
    Picker("Picker", selection: $pickerSelection, content: {
      Text("Video").tag(1)
      Text("Live").tag(2)
    })
    .pickerStyle(SegmentedPickerStyle())
  }

  var videoRecognizer: some View {
    VStack {
      Text(url.absoluteString)
        .onChange(of: url, perform: { value in
          poseRecognizer.recognizeYogaPose(from: url) { _ in print("done") }
        })
    }
    .navigationBarItems(trailing: plusButton)
  }

  var liveRecognizer: some View {
    VStack {
      LiveRecognizerViewController.LiveRecognizerViewRepresentable()
    }
    .navigationBarHidden(true)
    .navigationBarTitle("")
  }

  var body: some View {
    NavigationView {
//      segmentedPicker
//      if pickerSelection == 1 {
//        videoRecognizer
//      } else {
        liveRecognizer
//      }
    }
    .fullScreenCover(isPresented: $showGallery) {
      VideoPicker(showVideoPicker: $showGallery, videoURL: $url)
    }
  }

}
