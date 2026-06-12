import SwiftData
import SwiftUI

struct SubjectTopicsView: View {
  let subjectId: Int
  let topics: [TopicDTO]

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @State private var showCreateTopic: Bool = false

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("讨论版")
          .foregroundStyle(topics.count > 0 ? .primary : .secondary)
          .font(.title3)
        if isAuthenticated {
          Button {
            showCreateTopic = true
          } label: {
            Image(systemName: "plus.bubble")
          }.buttonStyle(.borderless)
        }
        Spacer()
        if topics.count > 0 {
          NavigationLink(value: NavDestination.subjectTopicList(subjectId)) {
            Text("更多讨论 »").font(.caption)
          }.buttonStyle(.navigation)
        }
      }
      Divider()
    }
    .padding(.top, 5)
    .sheet(isPresented: $showCreateTopic) {
      CreateTopicBoxSheet(type: .subject(subjectId)) {
        Task {
          try? await SubjectRepository.loadSubjectDetails(subjectId, offprints: false, social: true)
        }
      }
    }
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
          SubjectTopicItemView(topic: topic)
        }
      }
    }
    .buttonStyle(.navigation)
    .animation(.default, value: topics)
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
