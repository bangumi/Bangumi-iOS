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

    LazyVStack(alignment: .leading, spacing: 4) {
      ForEach(items) { item in
        let trigger = NextPagePrefetchTaskKey(
          triggerId: nextPageTrigger.triggerId(for: item.id),
          itemCount: items.count,
          resetToken: paginationResetToken
        )
        CardView {
          ProgressListItemContentView(
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

struct ProgressPageFooterView: View {
  let isLoading: Bool
  let hasMore: Bool

  var body: some View {
    HStack {
      Spacer()
      ZStack {
        ProgressView()
          .opacity(isLoading ? 1 : 0)

        Text("没有更多了")
          .font(.footnote)
          .foregroundStyle(.secondary)
          .opacity(!isLoading && !hasMore ? 1 : 0)
      }
      Spacer()
    }
    .frame(height: 28)
    .padding(.vertical, 4)
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

      ProgressSubjectLinearBarsView(subject: subject)
    }
  }
}
