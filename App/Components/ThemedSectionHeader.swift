import SwiftUI

struct ThemedSectionHeader<Title: View, Trailing: View>: View {
  let title: Title
  let systemImage: String?
  let classicFont: Font?
  let tintsTitle: Bool
  let trailing: Trailing

  @Environment(\.theme) private var theme

  fileprivate init(
    title: Title, systemImage: String?, classicFont: Font?, tintsTitle: Bool,
    trailing: Trailing
  ) {
    self.title = title
    self.systemImage = systemImage
    self.classicFont = classicFont
    self.tintsTitle = tintsTitle
    self.trailing = trailing
  }

  init(@ViewBuilder title: () -> Title, @ViewBuilder trailing: () -> Trailing) {
    self.init(
      title: title(), systemImage: nil, classicFont: nil, tintsTitle: false,
      trailing: trailing())
  }

  @ViewBuilder
  var body: some View {
    if theme.isClassic {
      classicBody
    } else {
      glassBody
    }
  }

  @ViewBuilder
  private var classicTitle: some View {
    if let classicFont {
      title.font(classicFont)
    } else {
      title
    }
  }

  private var classicBody: some View {
    HStack(alignment: .bottom) {
      classicTitle
      Spacer()
      trailing
    }
  }

  @ViewBuilder
  private var glassTitle: some View {
    if tintsTitle {
      title
        .font(.subheadline.weight(.heavy))
        .foregroundStyle(theme.sectionHeader)
    } else {
      title.font(.subheadline.weight(.heavy))
    }
  }

  private var glassBody: some View {
    HStack(alignment: .firstTextBaseline, spacing: 6) {
      if let systemImage {
        Image(systemName: systemImage)
          .font(.caption.weight(.bold))
          .foregroundStyle(theme.accent)
      }
      glassTitle
      Spacer(minLength: 0)
      trailing
    }
    .padding(.horizontal, 2)
  }
}

extension ThemedSectionHeader where Trailing == EmptyView {
  init(@ViewBuilder title: () -> Title) {
    self.init(title: title) { EmptyView() }
  }
}

extension ThemedSectionHeader where Title == Text {
  init(
    _ title: String,
    systemImage: String? = nil,
    @ViewBuilder trailing: () -> Trailing
  ) {
    self.init(
      title: Text(title), systemImage: systemImage, classicFont: .title3, tintsTitle: true,
      trailing: trailing())
  }
}

extension ThemedSectionHeader where Title == Text, Trailing == EmptyView {
  init(_ title: String, systemImage: String? = nil) {
    self.init(title, systemImage: systemImage) { EmptyView() }
  }
}
