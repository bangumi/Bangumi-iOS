import SwiftUI

final class ProgressSubjectRenderPayload {
  let item: ProgressSubjectDTO

  init(_ item: ProgressSubjectDTO) {
    self.item = item
  }
}

struct ProgressListView: View {
  let items: [ProgressSubjectDTO]
  let isLoadingPage: Bool
  let hasMore: Bool
  let loadNextPage: () async -> Void
  let reloadSubject: (Int) async -> Void

  @AppStorage("episodeGridInteractionMode") private var episodeGridInteractionMode:
    EpisodeGridInteractionMode = .menu

  var body: some View {
    LazyVStack(alignment: .leading) {
      ForEach(items.withNextPageTriggers()) { row in
        CardView {
          ProgressListItemContentView(
            payload: ProgressSubjectRenderPayload(row.item),
            interactionMode: episodeGridInteractionMode,
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

      ProgressPageFooterView(isLoading: isLoadingPage, hasMore: hasMore)
    }
    .padding(.horizontal, 8)
  }
}

struct ProgressPageFooterView: View {
  let isLoading: Bool
  let hasMore: Bool

  var body: some View {
    HStack {
      Spacer()
      if isLoading {
        ProgressView()
      } else if !hasMore {
        Text("没有更多了")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      Spacer()
    }
    .padding(.vertical, 8)
  }
}

struct ProgressListItemContentView: View {
  let payload: ProgressSubjectRenderPayload
  let interactionMode: EpisodeGridInteractionMode
  let reload: () async -> Void

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  private var item: ProgressSubjectDTO {
    payload.item
  }

  private var subject: SubjectDTO {
    item.subject
  }

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
            EpisodeRecentView(
              payload: EpisodeRecentPayload(item),
              mode: .list,
              interactionMode: interactionMode,
              reload: reload
            )

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
        payload: ProgressSubjectRenderPayload(
          ProgressSubjectDTO(
            subject: SubjectDTO(subject),
            episodes: episodes.map(EpisodeDTO.init)
          )
        ),
        interactionMode: .menu,
        reload: {}
      )
      .modelContainer(container)
    }.padding()
  }
}
