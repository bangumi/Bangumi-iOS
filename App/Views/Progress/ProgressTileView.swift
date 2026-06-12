import SwiftUI

struct ProgressTileView: View {
  let items: [ProgressSubjectDTO]
  let isLoadingPage: Bool
  let hasMore: Bool
  let loadNextPage: () async -> Void
  let reloadSubject: (Int) async -> Void

  var body: some View {
    VStack(spacing: 8) {
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
        ForEach(items.withNextPageTriggers()) { row in
          CardView(padding: 8) {
            ProgressTileItemContentView(
              subject: row.item.subject,
              episodes: row.item.episodes,
              reload: {
                await reloadSubject(row.item.id)
              }
            )
          }
          .onAppear {
            guard row.triggersNextPage, hasMore, !isLoadingPage else {
              return
            }
            Task {
              await loadNextPage()
            }
          }
        }
      }

      ProgressPageFooterView(isLoading: isLoadingPage, hasMore: hasMore)
    }
    .padding(.horizontal, 8)
  }
}

struct ProgressTileItemContentView: View {
  let subject: SubjectDTO
  let episodes: [EpisodeDTO]
  let reload: () async -> Void

  @AppStorage("subjectImageQuality") var subjectImageQuality: ImageQuality = .high
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  var body: some View {
    let subjectId = subject.id
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
            .imageStyle(contentMode: .fill)
        )

      VStack(alignment: .leading, spacing: 4) {
        VStack(alignment: .leading, spacing: 4) {
          NavigationLink(value: NavDestination.subject(subjectId)) {
            Text(subject.title(with: titlePreference))
              .font(.headline)
              .lineLimit(1)
          }.buttonStyle(.scale)

          ProgressSecondLineView(subject: subject)
        }

        Spacer(minLength: 0)

        switch subject.type {
        case .anime, .real:
          EpisodeRecentView(subject: subject, mode: .tile, episodes: episodes, reload: reload)
        case .book:
          SubjectBookChaptersView(subject: subject, mode: .tile, reload: reload)

        default:
          Label(
            subject.type.description,
            systemImage: subject.type.icon
          )
          .foregroundStyle(.accent)
        }

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
        ProgressTileItemContentView(
          subject: SubjectDTO(subject),
          episodes: episodes.map(EpisodeDTO.init),
          reload: {}
        )
          .modelContainer(container)
      }
    }.padding()
  }
}
