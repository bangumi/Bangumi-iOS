import OSLog
import SwiftUI

struct TimelineListView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("timelineViewMode") var timelineViewMode: TimelineViewMode = .friends

  @State private var showInput = false

  @State private var exhausted: Bool = false
  @State private var loading: Bool = false
  @State private var lastID: Int?
  @State private var fetched: [Int: Bool] = [:]
  @State private var items: [TimelineDTO] = []

  func reload() async {
    do {
      var data: [TimelineDTO] = []
      switch timelineViewMode {
      case .all:
        data = try await TimelineService.getTimeline(mode: .all, limit: 20, until: nil)
      case .friends:
        data = try await TimelineService.getTimeline(mode: .friends, limit: 20, until: nil)
      case .me:
        data = try await UserService.getUserTimeline(
          username: profile.username, limit: 20, until: nil)
      }
      if data.count == 0 {
        Notifier.shared.notify(message: "没有新动态")
        return
      }
      withAnimation(.default) {
        exhausted = false
        items = data
        fetched = [:]
        lastID = data.last?.id
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func loadNextPage(triggerID: TimelineDTO.ID) async {
    if loading {
      return
    }
    if exhausted {
      return
    }
    if lastID != triggerID {
      return
    }
    if fetched[triggerID] == true {
      return
    }
    withAnimation(.default) {
      loading = true
    }
    do {
      var data: [TimelineDTO] = []
      switch timelineViewMode {
      case .all:
        data = try await TimelineService.getTimeline(mode: .all, limit: 20, until: triggerID)
      case .friends:
        data = try await TimelineService.getTimeline(mode: .friends, limit: 20, until: triggerID)
      case .me:
        data = try await UserService.getUserTimeline(
          username: profile.username, limit: 20, until: triggerID)
      }
      if data.count == 0 {
        exhausted = true
      }
      fetched[triggerID] = true
      items.append(contentsOf: data)
      lastID = data.last?.id
    } catch {
      Notifier.shared.alert(error: error)
    }
    withAnimation(.default) {
      loading = false
    }
  }

  var body: some View {
    let rows = items.timelineListRows(lastID: lastID)

    ScrollView {
      VStack {
        if isAuthenticated {
          HStack {
            Text("Hi! \(profile.nickname.withLink(profile.link))")
              .font(.title3)
              .lineLimit(1)
            Spacer()
            if loading, items.count > 0 {
              ProgressView()
            }
            Picker("", selection: $timelineViewMode.animated()) {
              ForEach(TimelineViewMode.allCases, id: \.self) { mode in
                Text(mode.desc).tag(mode)
              }
            }
            .disabled(loading)
            .onChange(of: timelineViewMode) {
              Task {
                withAnimation(.default) {
                  loading = true
                }
                await reload()
                withAnimation(.default) {
                  loading = false
                }
              }
            }
            Button {
              showInput = true
            } label: {
              Label("吐槽", systemImage: "square.and.pencil")
                .font(.footnote)
            }
            .adaptiveButtonStyle(.borderedProminent)
            .disabled(showInput)
            .sheet(isPresented: $showInput) {
              TimelineSayView()
            }
          }
        } else {
          AuthView(slogan: "Bangumi 让你的 ACG 生活更美好")
            .frame(height: 100)
        }
      }.padding(8)
      LazyVStack(alignment: .leading) {
        ForEach(rows) { row in
          TimelineItemView(
            item: row.item,
            previousUID: row.previousUID
          )
          .padding(.bottom, 8)
          .task(id: row.nextPageTriggerID) {
            if let triggerID = row.nextPageTriggerID {
              await loadNextPage(triggerID: triggerID)
            }
          }
        }
        if loading {
          HStack {
            Spacer()
            ProgressView()
            Spacer()
          }
        }
      }.padding(.horizontal, 8)
    }
    .task {
      if items.count > 0 {
        return
      }
      withAnimation(.default) {
        loading = true
      }
      await reload()
      withAnimation(.default) {
        loading = false
      }
    }
    .refreshable {
      await reload()
    }
  }
}
