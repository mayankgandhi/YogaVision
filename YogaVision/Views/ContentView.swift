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

    var videoRecognizerView: some View {
        VStack {
            Text(url.absoluteString)
                .onChange(of: url, perform: { _ in
                    videoRecognizer.recognizeYogaPose(from: url)
                })
        }
        .navigationBarItems(trailing: plusButton)
    }

    var liveRecognizerView: some View {
        ZStack(alignment: .bottomLeading) {
            LiveRecognizerViewController.LiveRecognizerViewRepresentable()
                .edgesIgnoringSafeArea(.top)
            HStack(alignment: .center, spacing: 20) {
                VStack {
                    Image("Mountain Pose").resizable().scaledToFit().frame(width: 100, height: 100, alignment: .center)
                    Text("\(mlInfo.mountainPose.description)")
                        .font(.headline)
                }
                .padding()
                Spacer()
                VStack {
                    Image("Plank").resizable().scaledToFit().frame(width: 100, height: 100, alignment: .center)
                    Text("\(mlInfo.plank.description)")
                        .font(.headline)
                }
                .padding()
            }
            .background(Color.gray.opacity(0.5))
            .cornerRadius(20)
            .padding()
        }
    }

    var body: some View {
        NavigationView {
            TabView {
                videoRecognizerView
                    .tabItem {
                        Label("Video", systemImage: "video.fill")
                    }

                liveRecognizerView
                    .tabItem {
                        Label("Live", systemImage: "livephoto")
                    }
            }
        }
        .fullScreenCover(isPresented: $showGallery) {
            VideoPicker(showVideoPicker: $showGallery, videoURL: $url)
        }
    }
}
