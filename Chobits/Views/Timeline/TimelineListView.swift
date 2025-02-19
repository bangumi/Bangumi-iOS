import OSLog
import SwiftData
import SwiftUI

struct TimelineListView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()

  @State private var showInput = false

  @State private var mode: TimelineMode = .friends

  @State private var exhausted: Bool = false
  @State private var loading: Bool = false
  @State private var lastID: Int?
  @State private var fetched: [Int: Bool] = [:]
  @State private var items: [TimelineDTO] = []

  func reload() async {
    do {
      let data = try await Chii.shared.getTimeline(mode: mode, limit: 20, until: nil)
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
      let data = try await Chii.shared.getTimeline(mode: mode, limit: 20, until: lastID)
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
            Picker("", selection: $mode) {
              ForEach(TimelineMode.allCases, id: \.self) { mode in
                Text(mode.desc).tag(mode)
              }
            }
            .disabled(loading)
            .onChange(of: mode) {
              Task {
                loading = true
                await reload()
                loading = false
              }
            }
            Button {
              showInput = true
            } label: {
              Label("吐槽", systemImage: "square.and.pencil")
                .font(.footnote)
            }
            .buttonStyle(.borderedProminent)
            .disabled(showInput)
            .sheet(isPresented: $showInput) {
              TimelineSayView()
                .presentationDetents(.init([.large]))
            }
          }
        } else {
          AuthView(slogan: "Bangumi 让你的 ACG 生活更美好")
            .frame(height: 100)
        }
      }.padding(8)
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
