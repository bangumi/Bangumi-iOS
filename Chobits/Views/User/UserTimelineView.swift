import SwiftUI

struct UserTimelineView: View {
  let user: SlimUserDTO

  @AppStorage("profile") var profile: Profile = Profile()

  @State private var exhausted: Bool = false
  @State private var loading: Bool = false
  @State private var lastID: Int?
  @State private var fetched: [Int: Bool] = [:]
  @State private var items: [TimelineDTO] = []

  var title: String {
    if user.id == profile.id {
      return "我的时空管理局"
    } else {
      return "\(user.nickname)的时空管理局"
    }
  }

  func reload() async {
    do {
      let data = try await Chii.shared.getUserTimeline(
        username: user.username, limit: 20, until: nil)
      if data.count == 0 {
        Notifier.shared.notify(message: "没有新动态")
        return
      }
      exhausted = false
      items = data
      fetched = [:]
      lastID = data.last?.id
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func loadNextPage(_ item: TimelineDTO) async {
    if loading {
      return
    }
    if exhausted {
      return
    }
    if lastID != nil, item.id != lastID {
      return
    }
    if fetched[item.id] == true {
      return
    }
    loading = true
    do {
      let data = try await Chii.shared.getUserTimeline(
        username: user.username, limit: 20, until: lastID)
      if data.count == 0 {
        exhausted = true
      }
      fetched[item.id] = true
      items.append(contentsOf: data)
      lastID = data.last?.id
    } catch {
      Notifier.shared.alert(error: error)
    }
    loading = false
  }
  var body: some View {
    ScrollView {
      UserSmallView(user: user)
        .padding(.top, 8)
        .padding(.horizontal, 8)
      LazyVStack(alignment: .leading, spacing: 16) {
        ForEach(Array(zip(items.indices, items)), id: \.1) { idx, item in
          TimelineItemView(
            item: item, previous: idx == items.startIndex ? nil : items[idx - 1]
          ).onAppear {
            Task {
              await loadNextPage(item)
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
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
    .animation(.default, value: items)
    .task {
      if items.count > 0 {
        return
      }
      loading = true
      await reload()
      loading = false
    }
    .refreshable {
      await reload()
    }
  }
}
