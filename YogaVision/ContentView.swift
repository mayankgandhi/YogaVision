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


  var plusButton: some View {
    Button {
      self.showGallery = true
    } label: {
      Image(systemName: "plus")
    }
  }

  var body: some View {
    NavigationView {
      VStack {
        Text(url.absoluteString)
          .onChange(of: url, perform: { value in
            poseRecognizer.recognizeYogaPose(from: url) { _ in print("done") }
          })
      }
      .navigationBarItems(trailing: plusButton)
    }
    .fullScreenCover(isPresented: $showGallery) {
      VideoPicker(showVideoPicker: $showGallery, videoURL: $url)
    }
  }

}
