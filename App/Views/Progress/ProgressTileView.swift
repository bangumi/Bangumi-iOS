import SwiftData
import SwiftUI

struct ProgressTileView: View {
  let subjectIds: [Int]

  var body: some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
      ForEach(subjectIds, id: \.self) { subjectId in
        CardView(padding: 8) {
          ProgressTileItemView(subjectId: subjectId)
        }
      }
    }
    .animation(.default, value: subjectIds)
    .padding(.horizontal, 8)
  }
}

struct ProgressTileItemView: View {
  let subjectId: Int

  @Query var subjects: [Subject]

  init(subjectId: Int) {
    self.subjectId = subjectId
    self._subjects = Query(filter: #Predicate<Subject> { $0.subjectId == subjectId })
  }

  var body: some View {
    if let subject = subjects.first {
      ProgressTileItemContentView(subject: subject)
    }
  }
}

struct ProgressTileItemContentView: View {
  @Bindable var subject: Subject

  @AppStorage("subjectImageQuality") var subjectImageQuality: ImageQuality = .high
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Environment(\.modelContext) var modelContext

  var body: some View {
    let subjectId = subject.subjectId
    VStack(alignment: .leading, spacing: 4) {
      Color.clear
        .aspectRatio(0.707, contentMode: .fit)
        .overlay(
          ImageView(img: subject.images?.resize(subjectImageQuality.mediumSize))
            .imageType(.subject)
            .imageBadge(show: subject.interest?.private ?? false) {
              Image(systemName: "lock")
            }
            .imageNavLink(subject.link)
        )

      VStack(alignment: .leading, spacing: 4) {
        VStack(alignment: .leading, spacing: 4) {
          NavigationLink(value: NavDestination.subject(subjectId)) {
            Text(subject.title(with: titlePreference))
              .font(.headline)
              .lineLimit(2)
              .fixedSize(horizontal: false, vertical: true)
          }.buttonStyle(.scale)

          ProgressSecondLineView(subject: subject)
        }

        Spacer(minLength: 0)

        switch subject.typeEnum {
        case .anime, .real:
          EpisodeRecentView(subject: subject, mode: .tile)
        case .book:
          SubjectBookChaptersView(subject: subject, mode: .tile)

        default:
          Label(
            subject.typeEnum.description,
            systemImage: subject.typeEnum.icon
          )
          .foregroundStyle(.accent)
        }

        switch subject.typeEnum {
        case .book:
          VStack(spacing: 1) {
            ProgressView(
              value: Float(min(subject.eps, subject.interest?.epStatus ?? 0)),
              total: Float(subject.eps))
            ProgressView(
              value: Float(min(subject.volumes, subject.interest?.volStatus ?? 0)),
              total: Float(subject.volumes))
          }.progressViewStyle(.linear)

        case .anime, .real:
          ProgressView(
            value: Float(min(subject.eps, subject.interest?.epStatus ?? 0)),
            total: Float(subject.eps)
          ).progressViewStyle(.linear)

        default:
          ProgressView(value: 0, total: 0).progressViewStyle(.linear)
        }
      }.frame(height: 128)
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  let episodes = Episode.previewAnime
  container.mainContext.insert(subject)
  for episode in episodes {
    container.mainContext.insert(episode)
  }

  return ScrollView {
    LazyVStack(alignment: .leading) {
      CardView(padding: 8) {
        ProgressTileItemView(subjectId: subject.subjectId)
          .modelContainer(container)
      }
    }.padding()
  }
}
