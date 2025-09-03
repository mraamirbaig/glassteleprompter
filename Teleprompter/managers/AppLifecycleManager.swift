////
////  AppLifecycleManager.swift
////  Teleprompter
////
////  Created by abaig on 14/06/2025.
////
//
//class AppLifecycleManager: ObservableObject {
//    static let shared = AppLifecycleManager()
//
//    func startObserving() {
//        NotificationCenter.default.addObserver(
//            forName: UIApplication.willTerminateNotification,
//            object: nil,
//            queue: .main
//        ) { [weak self] _ in
//            print("App is being terminated")
//            self?.handleAppTermination()
//        }
//    }
//
//    private func handleAppTermination() {
//        FlutterChannelHandler.shared.removeBmpImage()
//    }
//}
//
