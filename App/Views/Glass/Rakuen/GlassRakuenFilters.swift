import SwiftUI

struct GlassRakuenFilters: View {
  @Binding var selection: RakuenListMode
  let isAuthenticated: Bool

  @Environment(\.theme) private var theme

  init(selection: Binding<RakuenListMode>, isAuthenticated: Bool) {
    self._selection = selection
    self.isAuthenticated = isAuthenticated
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      ForEach(RakuenCategory.allCases, id: \.self) { category in
        categoryRow(category)
      }
    }
  }

  private func categoryRow(_ category: RakuenCategory) -> some View {
    HStack(spacing: 8) {
      Text(category.description)
        .font(.caption2.weight(.bold).monospaced())
        .foregroundStyle(theme.tertiaryText)
        .frame(width: 56, alignment: .leading)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(category.modes, id: \.self) { mode in
            if isAuthenticated || !mode.requiresLogin {
              GlassChip(title: mode.description, isSelected: selection == mode) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                  selection = mode
                }
              }
            } else {
              lockedChip(mode)
            }
          }
        }
        .padding(.vertical, 3)
      }
      .scrollClipDisabled()
    }
  }

  private func lockedChip(_ mode: RakuenListMode) -> some View {
    GlassAuthButton {
      HStack(spacing: 4) {
        Text(mode.description)
        Image(systemName: "lock.fill")
          .font(.system(size: 9, weight: .semibold))
      }
      .font(.caption.weight(.semibold))
      .foregroundStyle(theme.tertiaryText)
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(theme.controlFill, in: Capsule())
      .overlay {
        Capsule().strokeBorder(theme.controlBorder, lineWidth: 1)
      }
      .contentShape(Capsule())
    }
    .buttonStyle(.plain)
  }
}
