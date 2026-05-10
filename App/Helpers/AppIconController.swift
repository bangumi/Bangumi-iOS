import Observation
import UIKit

enum AlternateAppIcon: String, CaseIterable {
  case primary
  case ukagaka

  init(iconName: String?) {
    switch iconName {
    case Self.ukagaka.iconName:
      self = .ukagaka
    default:
      self = .primary
    }
  }

  var iconName: String? {
    switch self {
    case .primary:
      nil
    case .ukagaka:
      "UkagakaIcon"
    }
  }

  var title: String {
    switch self {
    case .primary:
      "默认"
    case .ukagaka:
      "班娘"
    }
  }
}

@MainActor
@Observable
final class AppIconController {
  let isAvailable = UIApplication.shared.supportsAlternateIcons
  private(set) var isUpdating = false
  var selection: AlternateAppIcon

  init() {
    selection = AlternateAppIcon(iconName: UIApplication.shared.alternateIconName)
  }

  func setIcon(_ icon: AlternateAppIcon) {
    guard isAvailable else {
      Notifier.shared.alert(message: "Alternate app icons are unavailable on this device.")
      return
    }

    guard selection != icon, !isUpdating else { return }

    isUpdating = true
    UIApplication.shared.setAlternateIconName(icon.iconName) { [weak self] error in
      Task { @MainActor in
        guard let self else { return }
        self.isUpdating = false
        if let error {
          Notifier.shared.alert(error: error)
          self.selection = AlternateAppIcon(iconName: UIApplication.shared.alternateIconName)
        } else {
          self.selection = icon
          Notifier.shared.notify(message: "应用图标已更新")
        }
      }
    }
  }
}
