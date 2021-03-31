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

    var videoRecognizerView: some View {
        VStack {
            Spacer()
            Text(url.absoluteString)
                .onChange(of: url, perform: { _ in
                    videoRecognizer.recognizeYogaPose(from: url)
                })
        }
        .navigationBarItems(trailing: plusButton)
    }

    var recognisedPoseView: some View {
        VStack(alignment: .center, spacing: 20) {
            ProgressView(mlInfo.progress > 50 ? "Performing prediction" : "Gathering Data…", value: mlInfo.progress, total: 100)
                .frame(width: 200, alignment: /*@START_MENU_TOKEN@*/ .center/*@END_MENU_TOKEN@*/)
            Text("\(mlInfo.plank > mlInfo.mountainPose ? "Plank" : "Mountain Pose")")
                .font(.headline)
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
            //      TabView {
            //        videoRecognizerView
            //          .tabItem {
            //            Label("Video", systemImage: "video.fill")
            //          }

            liveRecognizerView
            //          .tabItem {
            //            Label("Live", systemImage: "livephoto")
            //          }
            //      }
        }
        //    .fullScreenCover(isPresented: $showGallery) {
        //      VideoPicker(showVideoPicker: $showGallery, videoURL: $url)
        //    }
    }
}
