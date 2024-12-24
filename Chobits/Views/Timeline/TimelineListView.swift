import OSLog
import SwiftData
import SwiftUI

struct TimelineListView: View {

  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()

  @State private var reloader = false
  @State private var showInput = false

  func load(limit: Int, offset: Int) async -> PagedDTO<TimelineDTO>? {
    do {
      let resp = try await Chii.shared.getTimeline(limit: limit, offset: offset)
      return PagedDTO(data: resp, total: 1000)
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      VStack {
        if isAuthenticated {
          HStack {
            Text("Hi! \(profile.nickname.withLink(profile.link))")
              .font(.title3)
              .padding(8)
            Spacer()
            Button {
              showInput = true
            } label: {
              Label("吐槽", systemImage: "square.and.pencil")
                .font(.footnote)
            }.buttonStyle(.borderedProminent)
          }
        } else {
          AuthView(slogan: "Bangumi 让你的 ACG 生活更美好")
            .frame(height: 100)
        }
      }.padding(.horizontal, 8)
      PageView<TimelineDTO, _>(reloader: reloader, nextPageFunc: load) { item in
        TimelineItemView(item: item)
      }.padding(.horizontal, 8)
    }
  }
}
