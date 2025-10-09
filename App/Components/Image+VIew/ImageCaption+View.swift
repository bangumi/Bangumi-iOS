import SwiftUI

extension View {
  @ViewBuilder
  func imageCaption<Overlay: View>(@ViewBuilder caption: () -> Overlay) -> some View {
    self
      .overlay {
        ZStack {
          Rectangle()
            .fill(
              LinearGradient(
                gradient: Gradient(colors: [
                  Color.black.opacity(0),
                  Color.black.opacity(0),
                  Color.black.opacity(0),
                  Color.black.opacity(0),
                  Color.black.opacity(0.1),
                  Color.black.opacity(0.2),
                  Color.black.opacity(0.4),
                  Color.black.opacity(0.8),
                ]), startPoint: .top, endPoint: .bottom))

          VStack {
            Spacer()
            caption()
          }
          .font(.caption)
          .foregroundStyle(.white)
          .padding(.bottom, 2)
        }.clipShape(RoundedRectangle(cornerRadius: 5))
      }
  }
}
