import SwiftUI

struct NotificationOverlayView: View {
  @State private var notifier = Notifier.shared

  @Environment(\.theme) private var theme

  private var toastShape: AnyShape {
    if theme.isClassic {
      return AnyShape(Capsule())
    }
    return AnyShape(
      RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous))
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      VStack(spacing: 8) {
        ForEach(notifier.notifications) { notification in
          Text(notification.message)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(theme.toastText)
            .background(theme.toastFill)
            .clipShape(toastShape)
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            .transition(
              .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .opacity.combined(with: .scale(scale: 0.9))
              ))
        }
      }
      .padding(.bottom, 64)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    .allowsHitTesting(false)
  }
}
