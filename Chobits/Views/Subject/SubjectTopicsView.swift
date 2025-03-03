import SwiftData
import SwiftUI

struct SubjectTopicsView: View {
  let subjectId: Int
  let topics: [TopicDTO]

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("讨论版")
          .foregroundStyle(topics.count > 0 ? .primary : .secondary)
          .font(.title3)
        Spacer()
        if topics.count > 0 {
          NavigationLink(value: NavDestination.subjectTopicList(subjectId)) {
            Text("更多讨论 »").font(.caption)
          }.buttonStyle(.navLink)
        }
      }
      Divider()
    }.padding(.top, 5)
    if topics.count == 0 {
      HStack {
        Spacer()
        Text("暂无讨论")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
      }.padding(.bottom, 5)
    }
    VStack {
      ForEach(topics) { topic in
        if !hideBlocklist || !blocklist.contains(topic.creator?.id ?? 0) {
          VStack {
            HStack {
              NavigationLink(value: NavDestination.subjectTopicDetail(topic.id)) {
                Text(topic.title)
                  .font(.callout)
                  .lineLimit(1)
              }.buttonStyle(.navLink)
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
          }.padding(.top, 2)
        }
      }
    }.animation(.default, value: topics)
  }
}

#Preview {
  NavigationStack {
    ScrollView {
      LazyVStack(alignment: .leading) {
        SubjectTopicsView(
          subjectId: Subject.previewAnime.subjectId, topics: Subject.previewTopics
        )
      }.padding()
    }.modelContainer(mockContainer())
  }
}
