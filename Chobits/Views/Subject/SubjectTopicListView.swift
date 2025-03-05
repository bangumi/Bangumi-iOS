import OSLog
import SwiftData
import SwiftUI

struct SubjectTopicListView: View {
  let subjectId: Int

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []

  @State private var reloader = false

  func load(limit: Int, offset: Int) async -> PagedDTO<TopicDTO>? {
    do {
      let resp = try await Chii.shared.getSubjectTopics(subjectId, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      PageView<TopicDTO, _>(reloader: reloader, nextPageFunc: load) { topic in
        if !hideBlocklist || !blocklist.contains(topic.creator?.id ?? 0) {
          VStack {
            HStack {
              NavigationLink(value: NavDestination.subjectTopicDetail(topic.id)) {
                Text(topic.title)
                  .font(.callout)
                  .lineLimit(1)
              }
              Spacer()
              if topic.replyCount ?? 0 > 0 {
                Text("(+\(topic.replyCount ?? 0))")
                  .font(.footnote)
                  .foregroundStyle(.orange)
              }
            }
            HStack {
              Text(topic.createdAt.dateDisplay)
                .lineLimit(1)
                .foregroundStyle(.secondary)
              Spacer()
              if let creator = topic.creator {
                Text(creator.nickname.withLink(creator.link))
                  .lineLimit(1)
              }
            }.font(.footnote)
            Divider()
          }.padding(.top, 2)
        }
      }.padding(.horizontal, 8)
    }
    .buttonStyle(.navigation)
    .navigationTitle("讨论版")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Image(systemName: "list.bullet.circle").foregroundStyle(.secondary)
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewAnime
  container.mainContext.insert(subject)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectTopicListView(subjectId: subject.subjectId)
    }.padding()
  }.modelContainer(container)
}
