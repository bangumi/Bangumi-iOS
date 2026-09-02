import Flow
import SwiftUI

struct GlassSubjectCollection: View {
  let subject: SubjectDTO
  let reload: () async -> Void

  @Environment(\.theme) private var theme
  @State private var edit: Bool = false

  private var controlShape: RoundedRectangle {
    RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
  }

  var body: some View {
    Group {
      if let interest = subject.interest {
        collectedCard(interest)
      } else {
        notCollectedCard
      }
    }
    .sheet(isPresented: $edit) {
      SubjectCollectionBoxView(subjectId: subject.id, initialSubject: subject)
        .presentationDragIndicator(.visible)
        .onDisappear {
          Task {
            await reload()
          }
        }
    }
  }

  private func collectedCard(_ interest: SubjectInterest) -> some View {
    CardView(padding: theme.metrics.cardPadding) {
      VStack(alignment: .leading, spacing: 10) {
        Button {
          edit.toggle()
        } label: {
          statusRow(interest)
        }
        .buttonStyle(.plain)

        field("收藏于") {
          Text("\(interest.updatedAt.datetimeDisplay) · \(interest.updatedAt.relativeAgeDisplay)")
            .font(.caption)
            .monospacedDigit()
            .foregroundStyle(theme.secondaryText)
        }

        if !interest.tags.isEmpty {
          field("我的标签") {
            HFlow(spacing: 5) {
              ForEach(interest.tags, id: \.self) { tag in
                Text(tag)
                  .font(.caption)
                  .foregroundStyle(theme.secondaryText)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 2)
                  .background(
                    theme.controlFill,
                    in: RoundedRectangle(
                      cornerRadius: theme.metrics.badgeRadius, style: .continuous)
                  )
                  .overlay {
                    RoundedRectangle(cornerRadius: theme.metrics.badgeRadius, style: .continuous)
                      .strokeBorder(theme.controlBorder, lineWidth: 1)
                  }
              }
            }
          }
        }

        if !interest.comment.isEmpty {
          field("我的短评") {
            Text(interest.comment)
              .font(.caption)
              .foregroundStyle(theme.secondaryText)
              .multilineTextAlignment(.leading)
              .textSelection(.enabled)
          }
        }

        if subject.type == .book {
          GlassSubjectBookProgress(subject: subject, reload: reload)
        }
      }
    }
  }

  private func statusRow(_ interest: SubjectInterest) -> some View {
    HStack(spacing: 9) {
      Text(interest.type.description(subject.type))
        .font(.caption.weight(.heavy))
        .foregroundStyle(theme.collectionBadgeText(interest.type))
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
        .background(
          LinearGradient(
            colors: theme.collectionBadge(interest.type),
            startPoint: .topLeading, endPoint: .bottomTrailing),
          in: RoundedRectangle(cornerRadius: theme.metrics.badgeRadius, style: .continuous)
        )
      StarsView(score: Float(interest.rate), size: 12)
      if interest.rate > 0 {
        Text("我打 \(interest.rate)")
          .font(.caption.weight(.bold))
          .monospaced()
          .foregroundStyle(theme.onTintText)
      }
      Spacer(minLength: 0)
      if interest.private {
        Image(systemName: "lock.fill")
          .font(.caption)
          .foregroundStyle(theme.placeholder)
      }
      Image(systemName: "chevron.right")
        .font(.caption)
        .foregroundStyle(theme.disabled)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(theme.tint, in: controlShape)
    .overlay {
      controlShape.strokeBorder(theme.accent.opacity(0.35), lineWidth: 1.5)
    }
  }

  private var notCollectedCard: some View {
    CardView(padding: theme.metrics.cardPadding) {
      Button {
        edit.toggle()
      } label: {
        HStack(spacing: 8) {
          Image(systemName: "plus")
            .font(.caption.weight(.heavy))
            .foregroundStyle(.white)
            .frame(width: 22, height: 22)
            .background(
              LinearGradient(
                colors: theme.ctaGradient,
                startPoint: .topLeading, endPoint: .bottomTrailing),
              in: Circle()
            )
          Text("未收藏 · 点击收藏本条目")
            .font(.subheadline.weight(.bold))
            .foregroundStyle(theme.onTintText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .background(theme.tint.opacity(0.5), in: controlShape)
        .overlay {
          controlShape.strokeBorder(
            theme.accent.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        }
      }
      .buttonStyle(.plain)
    }
  }

  private func field<Content: View>(
    _ label: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    HStack(alignment: .top, spacing: 10) {
      Text(label)
        .font(.caption2.weight(.semibold))
        .monospaced()
        .foregroundStyle(theme.placeholder)
        .frame(width: 56, alignment: .leading)
      content()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}
