import SwiftUI

struct NotificationOverlayView: View {
  @State private var notifier = Notifier.shared

  var body: some View {
    ZStack(alignment: .bottom) {
      VStack(spacing: 8) {
        ForEach(notifier.notifications) { notification in
          Text(notification.message)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(.white)
            .background(.accent)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            .transition(.asymmetric(
              insertion: .move(edge: .bottom).combined(with: .opacity),
              removal: .opacity.combined(with: .scale(scale: 0.9))
            ))
        }
      }
      .padding(.bottom, 64)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    .animation(.snappy, value: notifier.notifications)
    .allowsHitTesting(false)
  }
}
