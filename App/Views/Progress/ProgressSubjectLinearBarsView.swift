import SwiftUI

struct ProgressSubjectLinearBarsView: View {
  let subject: SubjectDTO

  var body: some View {
    switch subject.type {
    case .book:
      VStack(spacing: 1) {
        ProgressLinearBarView(
          value: Double(min(subject.eps, subject.interest?.epStatus ?? 0)),
          total: Double(subject.eps)
        )
        ProgressLinearBarView(
          value: Double(min(subject.volumes, subject.interest?.volStatus ?? 0)),
          total: Double(subject.volumes)
        )
      }

    case .anime, .real:
      ProgressLinearBarView(
        value: Double(min(subject.eps, subject.interest?.epStatus ?? 0)),
        total: Double(subject.eps)
      )

    default:
      ProgressLinearBarView(value: 0, total: 0)
    }
  }
}

private struct ProgressLinearBarView: View {
  let value: Double
  let total: Double

  private var fraction: CGFloat {
    guard value.isFinite, total.isFinite, total > 0 else {
      return 0
    }
    return CGFloat(min(max(value / total, 0), 1))
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
          .fill(Color.secondary.opacity(0.2))

        if fraction > 0 {
          RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(Color.accentColor)
            .frame(width: geometry.size.width * fraction)
        }
      }
    }
    .frame(height: 4)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Progress")
    .accessibilityValue("\(Int((fraction * 100).rounded()))%")
  }
}
