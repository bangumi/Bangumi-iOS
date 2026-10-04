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

  private func insertion(for notification: Notifier.Notification) -> AnyTransition {
    if notification.replacing {
      return .move(edge: .bottom).combined(with: .opacity)
    }
    return .scale(scale: 0.96).combined(with: .opacity)
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      VStack(spacing: 8) {
        ForEach(notifier.notifications) { notification in
          toastView(notification)
        }
      }
      .padding(.bottom, 64)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
  }

  @ViewBuilder
  private func toastView(_ notification: Notifier.Notification) -> some View {
    HStack(spacing: 8) {
      ToastCountdownRing(notification: notification)
      Text(notification.message)
      if let action = notification.action {
        Button {
          action.handler()
          notifier.dismiss(notification)
        } label: {
          Text(action.title)
            .bold()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .foregroundStyle(theme.toastText)
    .background(theme.toastFill)
    .clipShape(toastShape)
    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    .transition(
      .asymmetric(
        insertion: insertion(for: notification),
        removal: .opacity.combined(with: .scale(scale: 0.96))
      ))
    // Passive toasts must not swallow taps on the content below; only actionable ones intercept.
    .allowsHitTesting(notification.action != nil)
  }
}

private struct ToastCountdownRing: View {
  let notification: Notifier.Notification

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.theme) private var theme

  private func remaining(at date: Date) -> CGFloat {
    let elapsed = date.timeIntervalSince(notification.createdAt)
    return CGFloat(min(1, max(0, 1 - elapsed / notification.duration)))
  }

  var body: some View {
    if reduceMotion {
      // The ring carries the remaining lifetime, so it stays visible; it just ticks discretely.
      TimelineView(.periodic(from: notification.createdAt, by: 1)) { context in
        ring(remaining: remaining(at: context.date))
      }
    } else {
      TimelineView(.animation) { context in
        ring(remaining: remaining(at: context.date))
      }
    }
  }

  private func ring(remaining: CGFloat) -> some View {
    ZStack {
      Circle()
        .stroke(theme.toastText.opacity(0.35), lineWidth: 2)
      Circle()
        .trim(from: 0, to: remaining)
        .stroke(theme.toastText, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        .rotationEffect(.degrees(-90))
      if let type = notification.type {
        Image(systemName: type == .success ? "checkmark" : "xmark")
          .font(.system(size: 7, weight: .bold))
      }
    }
    .frame(width: 16, height: 16)
  }
}
