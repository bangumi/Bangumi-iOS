import SwiftData
import SwiftUI

struct IndexRelatedSubjectItemView: View {
  @Binding var reloader: Bool
  let item: IndexRelatedDTO
  let isOwner: Bool
  var indexAwardYear: Int? = nil

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original
  @Query private var subjects: [Subject]
  @State private var showCollectionBox = false

  init(reloader: Binding<Bool>, item: IndexRelatedDTO, isOwner: Bool, indexAwardYear: Int? = nil) {
    self._reloader = reloader
    self.item = item
    self.isOwner = isOwner
    self.indexAwardYear = indexAwardYear
    let subjectId = item.subject?.id ?? 0
    let predicate = #Predicate<Subject> { $0.subjectId == subjectId }
    _subjects = Query(filter: predicate)
  }

  private var subject: Subject? {
    subjects.first
  }

  var body: some View {
    HStack(alignment: .top) {
      if let itemSubject = item.subject {
        ImageView(img: itemSubject.images?.resize(.r200))
          .imageStyle(width: 80, height: 100)
          .imageType(.subject)
          .imageNSFW(itemSubject.nsfw)
          .imageNavLink(itemSubject.link)
        VStack(alignment: .leading) {
          HStack(spacing: 4) {
            Image(systemName: itemSubject.type.icon)
              .foregroundStyle(.secondary)
              .font(.footnote)
            if let year = indexAwardYear, let awardName = item.awardName(year: year) {
              BadgeView(background: .blue) {
                Text(awardName)
                  .font(.caption2)
                  .bold()
                  .foregroundStyle(.white)
              }
              .shadow(radius: 1)
            }
            Text(itemSubject.title(with: titlePreference).withLink(itemSubject.link))
              .lineLimit(1)
            Spacer(minLength: 0)
          }
          if let subtitle = itemSubject.subtitle(with: titlePreference) {
            Text(subtitle)
              .font(.footnote)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
          Text(itemSubject.info ?? "")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(2)
          if !item.comment.isEmpty {
            BorderView(color: .secondary.opacity(0.2), padding: 4) {
              HStack {
                Text(item.comment)
                  .font(.footnote)
                  .textSelection(.enabled)
                Spacer(minLength: 0)
              }
            }
          }
          Spacer(minLength: 0)
        }
        .overlay(alignment: .bottomTrailing) {
          Button {
            showCollectionBox = true
          } label: {
            if let ctype = subject?.ctypeEnum, ctype != .none {
              HStack(spacing: 4) {
                Image(systemName: ctype.icon)
                  .font(.caption2)
                Text(ctype.description(itemSubject.type))
              }
              .foregroundStyle(ctype.color)
            } else {
              Text("收藏")
            }
          }
          .adaptiveButtonStyle(.bordered)
          .font(.caption)
          .controlSize(.mini)
        }
      } else {
        Text("神秘的条目")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      Spacer(minLength: 0)
    }
    .sheet(isPresented: $showCollectionBox) {
      if let subjectId = item.subject?.id {
        SubjectCollectionBoxView(subjectId: subjectId)
      }
    }
  }
}
