import SwiftUI

struct ProgressListView: View {
  let subjectIds: [Int]
  let reloadToken: Int

  var body: some View {
    LazyVStack(alignment: .leading) {
      ForEach(subjectIds, id: \.self) { subjectId in
        ProgressSubjectContainerView(
          subjectId: subjectId,
          reloadToken: reloadToken,
          episodeWindowSize: 7
        ) { item, reload in
          CardView {
            ProgressListItemContentView(
              subject: item.subject,
              episodes: item.episodes,
              reload: reload
            )
          }
          .transition(.opacity)
        }
      }
    }
    .padding(.horizontal, 8)
  }
}

struct ProgressListItemContentView: View {
  let subject: SubjectDTO
  let episodes: [EpisodeDTO]
  let reload: () async -> Void

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  var body: some View {
    let subjectId = subject.id
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        ImageView(img: subject.images?.resize(.r200))
          .imageStyle(width: 72, height: 72)
          .imageType(.subject)
          .imageBadge(show: subject.interest?.private ?? false) {
            Image(systemName: "lock")
          }
          .imageNavLink(subject.link)
        VStack(alignment: .leading, spacing: 4) {
          NavigationLink(value: NavDestination.subject(subjectId)) {
            VStack(alignment: .leading, spacing: 4) {
              Text(subject.title(with: titlePreference))
                .font(.headline)
                .lineLimit(1)
              ProgressSecondLineView(subject: subject)
            }
          }.buttonStyle(.scale)

          Spacer()

          switch subject.type {
          case .anime, .real:
            EpisodeRecentView(subject: subject, mode: .list, episodes: episodes, reload: reload)

          case .book:
            SubjectBookChaptersView(subject: subject, mode: .row, reload: reload)

          default:
            Label(
              subject.type.description,
              systemImage: subject.type.icon
            )
            .foregroundStyle(.accent)
            .font(.callout)
          }
        }
      }

      Section {
        switch subject.type {
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
          )
          .progressViewStyle(.linear)

        default:
          ProgressView(value: 0, total: 0)
            .progressViewStyle(.linear)
        }
      }
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
      ProgressListItemContentView(
        subject: SubjectDTO(subject),
        episodes: episodes.map(EpisodeDTO.init),
        reload: {}
      )
        .modelContainer(container)
    }.padding()
  }
}
