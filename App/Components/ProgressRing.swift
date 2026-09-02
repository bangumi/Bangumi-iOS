import SwiftUI

struct ProgressRing: View {
  let current: Int
  let total: Int?

  @Environment(\.theme) private var theme

  init(current: Int, total: Int?) {
    self.current = current
    self.total = total
  }

  private var progress: Double {
    guard let total, total > 0 else {
      return 0
    }
    return min(1, Double(current) / Double(total))
  }

  var body: some View {
    ZStack {
      Circle()
        .stroke(theme.track, lineWidth: 5)
      if total != nil {
        Circle()
          .trim(from: 0, to: progress)
          .stroke(theme.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
          .rotationEffect(.degrees(-90))
      }
      HStack(alignment: .firstTextBaseline, spacing: 0) {
        Text("\(current)")
          .font(.system(size: 13, weight: .bold, design: .monospaced))
          .foregroundStyle(theme.accent)
        if let total {
          Text("/\(total)")
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundStyle(theme.disabled)
        }
      }
    }
    .frame(width: 56, height: 56)
  }
}
