import SwiftUI

struct StarsView: View {
  let score: Float
  let size: CGFloat

  @Environment(\.theme) private var theme

  var rate: Int {
    Int(score.rounded())
  }

  var body: some View {
    if theme.isClassic {
      HStack {
        ForEach(1..<6) { idx in
          star(idx)
            .padding(.horizontal, -3)
        }
      }
    } else {
      HStack(spacing: 2) {
        ForEach(1..<6) { idx in
          star(idx)
        }
      }
    }
  }

  private func star(_ idx: Int) -> some View {
    Image(
      systemName: idx * 2 <= rate
        ? "star.fill"
        : idx * 2 - 1 == rate ? "star.leadinghalf.fill" : "star"
    )
    .resizable()
    .foregroundStyle(theme.star)
    .frame(width: size, height: size)
  }
}
