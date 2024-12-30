import SwiftUI

struct UserSmallView: View {
  let user: SlimUserDTO
  var body: some View {
    HStack {
      ImageView(img: user.avatar?.large)
        .imageStyle(width: 40, height: 40)
        .imageType(.avatar)
      VStack(alignment: .leading) {
        Text(user.nickname)
          .lineLimit(1)
        Text("@\(user.username)")
          .foregroundStyle(.secondary)
          .font(.footnote)
      }
      Spacer()
    }
    .padding(5)
    .overlay {
      RoundedRectangle(cornerRadius: 8)
        .inset(by: 1)
        .stroke(.secondary.opacity(0.2), lineWidth: 1)
    }
    .background(.secondary.opacity(0.01))
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}
