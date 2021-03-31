 
 # Yoga Vision
 
After seeing the new advancements in Vision and CoreML, I thought it would be cool to build an app that detects various Yoga Poses. Before we get into building the simple yoga pose recognition app.

Checkout my Medium article - Where I document the process of building this app - 
[Medium Article](https://mayankgandhi50.medium.com/building-an-ios-app-that-detects-yoga-poses-part-1-de4f9c726682 "Building an iOS app that detects Yoga poses")
 
 ## Preview (Youtube Preview Links)
 
[![Live Recognizer Preview](https://img.youtube.com/vi/WluGu5gdRXU/0.jpg)](https://www.youtube.com/watch?v=WluGu5gdRXU)

[![Video Recognizer Preview](https://img.youtube.com/vi/AxNYRU1NQ9U/0.jpg)](https://www.youtube.com/watch?v=AxNYRU1NQ9U)


 ## Folder Structure
 ```
📦Files
 ┣ 📂MLModels
 ┃ ┣ 📜YogaImageClassifier.mlmodel
 ┃ ┗ 📜YogaVision.mlmodel
 ┣ 📂Recognizer
 ┃ ┣ 📜FileService.swift
 ┃ ┣ 📜LiveRecognizer.swift
 ┃ ┣ 📜PoseRecognizer.swift
 ┃ ┗ 📜VideoRecognizer.swift
 ┣ 📂System
 ┃ ┣ 📜AppDelegate+Injection.swift
 ┃ ┣ 📜AppDelegate.swift
 ┃ ┗ 📜SceneDelegate.swift
 ┣ 📂VideoComponents
 ┃ ┣ 📜VideoPicker.swift
 ┃ ┗ 📜VideoPlayer.swift
 ┣ 📂ViewControllers
 ┃ ┣ 📜CameraBufferViewController.swift
 ┃ ┣ 📜LiveRecognizerViewController.swift
 ┃ ┗ 📜MLInfo.swift
 ┗ 📂Views
 ┃ ┣ 📜ContentView.swift
 ┃ ┣ 📜LiveRecognizer+Representable.swift
 ┃ ┗ 📜TabSwitcherView.swift
 ```
