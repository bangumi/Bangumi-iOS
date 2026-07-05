import OSLog
import SwiftUI

struct SubjectSlimRowView: View {
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  let subject: SlimSubjectDTO
  let collectionType: CollectionType

  var body: some View {
    HStack {
      ImageView(img: subject.images?.resize(.r200))
        .imageCollectionStatus(ctype: collectionType)
        .imageStyle(width: 90, height: subject.type.coverHeight(for: 90))
        .imageType(.subject)
        .imageNSFW(subject.nsfw)
        .imageNavLink(subject.link)
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 4) {
          VStack(alignment: .leading) {
            HStack(spacing: 4) {
              if subject.type != .none {
                Image(systemName: subject.type.icon)
                  .foregroundStyle(.secondary)
                  .font(.footnote)
              }
              Text(subject.title(with: titlePreference).withLink(subject.link))
                .font(.headline)
                .lineLimit(1)
            }
          }
          Spacer(minLength: 0)
          if let rating = subject.rating, rating.rank > 0 {
            Label(String(rating.rank), systemImage: "chart.bar.xaxis")
              .foregroundStyle(.accent)
              .font(.footnote)
          }
        }

        if let subtitle = subject.subtitle(with: titlePreference) {
          Text(subtitle)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        if let info = subject.info, !info.isEmpty {
          Text(info)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }

        HStack(spacing: 4) {
          if subject.type != .none {
            BorderView {
              Text(subject.type.description).lineLimit(1)
            }
          }
          if !subject.metaTags.isEmpty {
            ForEach(subject.metaTags, id: \.self) { tag in
              Text(tag)
                .lineLimit(1)
                .padding(2)
                .background(.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
          }
        }
        .foregroundStyle(.secondary)
        .font(.caption)

        if let rating = subject.rating {
          HStack {
            if rating.total > 10, rating.score > 0 {
              StarsView(score: rating.score, size: 12)
              Text("\(rating.score.rateDisplay)")
                .font(.callout)
                .foregroundStyle(.orange)
              Text("(\(rating.total)人评分)")
                .foregroundStyle(.secondary)
            } else {
              StarsView(score: 0, size: 12)
              Text("(少于10人评分)")
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
          }
          .font(.footnote)
        }
      }.padding(.leading, 2)
    }
    .frame(minHeight: subject.type.coverHeight(for: 90))
    .padding(2)
    .clipShape(RoundedRectangle(cornerRadius: 10))
  }
}

struct SubjectSlimListItemView: View {
  let subject: SlimSubjectDTO
  let initialCollectionType: CollectionType

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

  var body: some View {
    CardView {
      SubjectSlimRowView(subject: subject, collectionType: collectionType)
        .subjectCollectionStatusOverlay(
          subjectId: subject.id,
          subjectType: subject.type,
          collectionType: collectionType,
          reload: loadCollectionType
        )
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
