import SwiftUI

struct RakuenGroupTopicView: View {
  let mode: GroupTopicFilterMode

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()

  @State private var reloader = false

  private func load(limit: Int, offset: Int) async -> PagedDTO<GroupTopicDTO>? {
    do {
      let resp = try await Chii.shared.getRecentGroupTopics(
        mode: mode, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
      return nil
    }
  }

  var body: some View {
    ScrollView {
      PageView<GroupTopicDTO, _>(reloader: reloader, nextPageFunc: load) { topic in
        if !hideBlocklist || !profile.blocklist.contains(topic.creator?.id ?? 0) {
          CardView {
            GroupTopicItemView(topic: topic)
          }
        }
      }.padding(.horizontal, 8)
    }
    .navigationTitle(mode.description)
    .navigationBarTitleDisplayMode(.inline)
    .refreshable {
      reloader.toggle()
    }
  }
}
