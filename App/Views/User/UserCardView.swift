import SwiftUI

struct UserSmallView: View {
  let user: SlimUserDTO

  @Environment(\.theme) private var theme

  private var embedShapeStyle: RoundedCornerStyle {
    theme.isClassic ? .circular : .continuous
  }

  var body: some View {
    HStack {
      ImageView(img: user.avatar?.large)
        .imageStyle(width: 40, height: 40)
        .imageType(.avatar)
        .imageLink(user.link)
      VStack(alignment: .leading) {
        Text(user.nickname.withLink(user.link))
          .lineLimit(1)
        Text("@\(user.username)")
          .foregroundStyle(.secondary)
          .font(.footnote)
      }
      Spacer()
    }
    .padding(5)
    .overlay {
      RoundedRectangle(cornerRadius: theme.metrics.embedRadius, style: embedShapeStyle)
        .inset(by: 1)
        .stroke(theme.embedBorder, lineWidth: 1)
    }
    .background(theme.embedFill)
    .clipShape(
      RoundedRectangle(cornerRadius: theme.metrics.embedRadius, style: embedShapeStyle))
  }
}
