import SwiftUI

struct SettingLabel: View {
  let title: LocalizedStringKey
  let description: LocalizedStringKey

  init(_ title: LocalizedStringKey, description: LocalizedStringKey) {
    self.title = title
    self.description = description
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
      Text(description)
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }
}
