import SwiftUI

struct ProgressTileView: View {
  let items: [ProgressSubjectDTO]
  let isLoadingPage: Bool
  let hasMore: Bool
  let prefetchWindow: Int
  let paginationResetToken: Int
  let loadNextPage: () async -> Bool
  let reloadSubject: (Int) async -> Void

  @AppStorage("episodeGridInteractionMode") private var episodeGridInteractionMode:
    EpisodeGridInteractionMode = .menu
  @State private var prefetchState = NextPagePrefetchState<ProgressSubjectDTO.ID>()

  private func requestNextPage(for trigger: NextPagePrefetchTaskKey<ProgressSubjectDTO.ID>) {
    if let triggerId = prefetchState.request(
      trigger: trigger,
      isLoading: isLoadingPage,
      canLoadMore: hasMore
    ) {
      Task {
        if await !loadNextPage() {
          prefetchState.cancelRequest(triggerId: triggerId)
        }
      }
    }
  }

  var body: some View {
    let nextPageTrigger = items.nextPagePrefetchTrigger(prefetchWindow: prefetchWindow)

    VStack(spacing: 8) {
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
        ForEach(items) { item in
          let trigger = NextPagePrefetchTaskKey(
            triggerId: nextPageTrigger.triggerId(for: item.id),
            itemCount: items.count,
            resetToken: paginationResetToken
          )
          CardView(padding: 8) {
            ProgressTileItemContentView(
              payload: ProgressSubjectRenderPayload(item),
              interactionMode: episodeGridInteractionMode,
              reload: {
                await reloadSubject(item.id)
              }
            )
          }
          .task(id: trigger) {
            requestNextPage(for: trigger)
          }
        }

      }

      ProgressPageFooterView(isLoading: isLoadingPage, hasMore: hasMore)
    }
    .padding(.horizontal, 8)
    .onChange(of: isLoadingPage) { _, isLoading in
      guard !isLoading else {
        return
      }
      prefetchState.completeLoading(canLoadMore: hasMore)
    }
    .onChange(of: paginationResetToken) { _, _ in
      prefetchState.reset()
    }
  }
}

struct ProgressTileItemContentView: View {
  let payload: ProgressSubjectRenderPayload
  let interactionMode: EpisodeGridInteractionMode
  let reload: () async -> Void

  @AppStorage("subjectImageQuality") var subjectImageQuality: ImageQuality = .high
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
          EpisodeRecentView(
            payload: EpisodeRecentPayload(item),
            mode: .tile,
            interactionMode: interactionMode,
            reload: reload
          )
        case .book:
          SubjectBookChaptersView(subject: subject, mode: .tile, reload: reload)

        default:
          Label(
            subject.type.description,
            systemImage: subject.type.icon
          )
          .foregroundStyle(.accent)
        }

        ProgressSubjectLinearBarsView(subject: subject)
      }.frame(height: 128)
    }
  }
}
