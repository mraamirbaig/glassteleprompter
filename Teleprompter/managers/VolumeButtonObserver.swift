//
//  VolumeButtonObserver.swift
//  Teleprompter
//
//  Created by abaig on 03/06/2025.
//

import AVFoundation
import Combine
import MediaPlayer

/// Keeps a silent audio track looping so the app stays audio‑active
/// (and therefore receives volume‑change events in the background).
final class SilentAudioPlayer {
    static let shared = SilentAudioPlayer()

    private var player: AVAudioPlayer?

    private init() {
        activateAudioSession()
    }

    /// Start (or resume) the silent loop.
    func start() {
        guard player == nil else { return }          // already playing?

        guard let url = Bundle.main.url(forResource: "silence",
                                        withExtension: "mp3") else {
            print("❌ silent.mp3 not found in bundle")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = .max              // infinite loop
            player?.volume = 0.01                    // inaudible
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("❌ Silent player failed: \(error)")
        }
    }

    /// Stop the loop (optional).
    func stop() {
        player?.stop()
        player = nil
    }

    // MARK: - Private

    private func activateAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("❌ Audio session error: \(error)")
        }
    }
}

import UIKit

final class VolumeButtonObserver: ObservableObject {

    var onVolumeUp  : (() -> Void)?
    var onVolumeDown: (() -> Void)?

    private let audioSession = AVAudioSession.sharedInstance()
    private var cancellable: AnyCancellable?
    private var lastVolume: Float = 0.5

    private let volumeView = MPVolumeView(frame: .zero)
    private var ignoreVolumeChanges = false

    func start() {
        try? audioSession.setActive(true)
        lastVolume = audioSession.outputVolume

        // Add hidden MPVolumeView to the active window (iOS 15+)
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            volumeView.isHidden = true
            window.addSubview(volumeView)
        }

        // Fix if volume is at edge on start
        if lastVolume <= 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.setSystemVolume(0.05)
            }
            lastVolume = 0.05
        } else if lastVolume >= 1.0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.setSystemVolume(0.95)
            }
            lastVolume = 0.95
        }

        cancellable = audioSession
            .publisher(for: \.outputVolume, options: [.new])
            .sink { [weak self] newVol in
                guard let self = self else { return }

                if self.ignoreVolumeChanges {
                    self.ignoreVolumeChanges = false
                    self.lastVolume = newVol
                    return
                }

                if newVol > self.lastVolume {
                    self.onVolumeUp?()
                } else if newVol < self.lastVolume {
                    self.onVolumeDown?()
                }

                // Handle volume boundaries to allow continuous detection
                if newVol <= 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.setSystemVolume(0.05)
                    }
                } else if newVol >= 1.0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.setSystemVolume(0.95)
                    }
                }

                self.lastVolume = newVol
            }
    }

    func stop() {
        cancellable = nil
        volumeView.removeFromSuperview()
        try? audioSession.setActive(false)
    }

    private func setSystemVolume(_ volume: Float) {
        guard let slider = volumeView.subviews.compactMap({ $0 as? UISlider }).first else { return }
        ignoreVolumeChanges = true
        slider.value = volume
    }
}

