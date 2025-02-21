import SwiftUI

struct RakuenGroupTopicView: View {
  @State private var reloader = false
  @State private var mode: GroupTopicFilterMode = .joined

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
      HStack {
        Picker("Mode", selection: $mode) {
          ForEach(GroupTopicFilterMode.allCases, id: \.self) { mode in
            Text(mode.description).tag(mode)
          }
        }.pickerStyle(.menu)
        Spacer()
      }.padding(.horizontal, 8)
      PageView<GroupTopicDTO, _>(reloader: reloader, nextPageFunc: load) { topic in
        CardView {
          HStack(alignment: .top) {
            ImageView(img: topic.creator?.avatar?.large)
              .imageStyle(width: 40, height: 40)
              .imageType(.avatar)
              .imageLink(topic.link)
            VStack(alignment: .leading) {
              Section {
                Text(topic.title.withLink(topic.link))
                  .font(.headline)
                  + Text("(+\(topic.replyCount))")
                  .font(.footnote)
                  .foregroundStyle(.secondary)
              }
              HStack {
                topic.updatedAt.relativeText
                  .font(.caption)
                  .foregroundStyle(.secondary)
                NavigationLink(value: NavDestination.group(topic.group.name)) {
                  Spacer()
                  Text(topic.group.title)
                    .font(.footnote)
                }.buttonStyle(.plain)
              }
            }
            Spacer()
          }
        }
      }.padding(8)
    }
    .navigationTitle("小组话题")
    .navigationBarTitleDisplayMode(.inline)
    .refreshable {
      reloader.toggle()
    }
  }
}
