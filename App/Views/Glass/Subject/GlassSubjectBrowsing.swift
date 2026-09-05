import Flow
import OSLog
import SwiftUI

struct GlassSubjectBrowseRow: View {
  let subject: SlimSubjectDTO
  let initialCollectionType: CollectionType

  @AppStorage("titlePreference") private var titlePreference: TitlePreference = .original

  @Environment(\.theme) private var theme

  @State private var collectionType: CollectionType

  init(subject: SlimSubjectDTO, collectionType: CollectionType) {
    self.subject = subject
    self.initialCollectionType = collectionType
    self._collectionType = State(initialValue: collectionType)
  }

  private func loadCollectionType() async {
    do {
      let db = try await AppContext.shared.getDB()
      collectionType =
        try await db.getCollectionTypes(subjectIds: [subject.id])[subject.id] ?? .none
    } catch {
      Logger.app.error("Failed to load subject collection type: \(error)")
    }
  }

  private func handleSubjectInvalidation(_ notification: Notification) {
    guard ProgressSubjectInvalidation.subjectId(from: notification) == subject.id else {
      return
    }
    Task {
      await loadCollectionType()
    }
  }

  @ViewBuilder
  private var ratingLine: some View {
    if let rating = subject.rating {
      HStack(spacing: 5) {
        if rating.total > 10, rating.score > 0 {
          Text(rating.score.rateDisplay)
            .font(.caption.weight(.heavy).monospaced())
            .foregroundStyle(theme.accentDeep)
          StarsView(score: rating.score, size: 9)
          Text("(\(rating.total)人评分)")
            .font(.caption2)
            .foregroundStyle(theme.tertiaryText)
        } else {
          StarsView(score: 0, size: 9)
          Text("(少于10人评分)")
            .font(.caption2)
            .foregroundStyle(theme.tertiaryText)
        }
        Spacer(minLength: 0)
      }
    }
  }

  private var details: some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(subject.title(with: titlePreference).withLink(subject.link, linkColor: theme.link))
        .font(.footnote.weight(.bold))
        .lineLimit(2)
      if let info = subject.info, !info.isEmpty {
        Text(info)
          .font(.caption2)
          .foregroundStyle(theme.tertiaryText)
          .lineLimit(2)
      }
      HFlow(spacing: 5) {
        if subject.type != .none {
          GlassTypeBadge(type: subject.type)
        }
        ForEach(subject.metaTags.prefix(5), id: \.self) { tag in
          GlassMonoTag(text: tag)
        }
      }
      ratingLine
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func rankMark(_ rank: Int) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 1) {
      Text(verbatim: "#")
        .font(.system(size: 11, weight: .heavy, design: .rounded))
      Text(verbatim: "\(rank)")
        .font(.system(size: 22, weight: .black, design: .rounded))
        .monospacedDigit()
    }
    .lineLimit(1)
    .minimumScaleFactor(0.6)
    .foregroundStyle(
      rank <= 3
        ? AnyShapeStyle(
          LinearGradient(colors: theme.ctaGradient, startPoint: .top, endPoint: .bottom))
        : AnyShapeStyle(theme.placeholder)
    )
    .frame(width: 44)
  }

  var body: some View {
    CardView(padding: theme.metrics.cardPadding) {
      HStack(alignment: .center, spacing: 10) {
        ImageView(img: subject.images?.resize(.r200))
          .imageCollectionStatus(ctype: collectionType)
          .imageStyle(
            width: 64, height: subject.type.coverHeight(for: 64),
            cornerRadius: theme.metrics.coverRadius
          )
          .imageType(.subject)
          .imageNSFW(subject.nsfw)
          .imageNavLink(subject.link)
        details
        VStack(spacing: 4) {
          if let rating = subject.rating, rating.rank > 0 {
            rankMark(rating.rank)
          }
          Spacer(minLength: 0)
          GlassCollectButton(
            subjectId: subject.id,
            subjectType: subject.type,
            collectionType: collectionType,
            reload: loadCollectionType
          )
          Spacer(minLength: 0)
        }
      }
    }
    .subjectPreview(subject, collectionType: collectionType) {
      await loadCollectionType()
    }
    .onChange(of: initialCollectionType) { _, newValue in
      collectionType = newValue
    }
    .onReceive(
      NotificationCenter.default.publisher(for: ProgressSubjectInvalidation.notificationName),
      perform: handleSubjectInvalidation
    )
  }
}
