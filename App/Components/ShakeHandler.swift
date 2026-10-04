import SwiftUI
import UIKit

struct ShakeHandler: UIViewControllerRepresentable {
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original
  @AppStorage("enableShakeTitleToggle") var enableShakeTitleToggle: Bool = false

  func makeUIViewController(context: Context) -> ShakeViewController {
    ShakeViewController()
  }

  func updateUIViewController(_ uiViewController: ShakeViewController, context: Context) {
    guard enableShakeTitleToggle else {
      uiViewController.onShake = nil
      return
    }

    uiViewController.onShake = {
      // Toggle between chinese and original
      titlePreference = titlePreference == .chinese ? .original : .chinese

      Haptics.impact(.medium)

      // Show notification
      let preferenceText = titlePreference == .chinese ? "中文名优先" : "原名优先"
      Notifier.shared.notify(message: "已切换为\(preferenceText)")
    }
  }
}

class ShakeViewController: UIViewController {
  var onShake: (() -> Void)?

  override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
    if motion == .motionShake {
      onShake?()
    }
  }
}
