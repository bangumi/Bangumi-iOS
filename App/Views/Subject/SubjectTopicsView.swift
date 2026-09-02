import SwiftUI

struct SubjectTopicsView: View {
  let subjectId: Int
  let topics: [TopicDTO]

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @Environment(\.theme) private var theme

  @State private var showCreateTopic: Bool = false

  private var createTopicButton: some View {
    Button {
      showCreateTopic = true
    } label: {
      Image(systemName: "plus.bubble")
    }.buttonStyle(.borderless)
  }

  private var moreLink: some View {
    NavigationLink(value: NavDestination.subjectTopicList(subjectId)) {
      Text("更多讨论 »").font(.caption)
    }.buttonStyle(.navigation)
  }

  var body: some View {
    Group {
      if theme.isClassic {
        VStack(spacing: 2) {
          HStack(alignment: .bottom) {
            Text("讨论版")
              .foregroundStyle(topics.count > 0 ? .primary : .secondary)
              .font(.title3)
            if isAuthenticated {
              createTopicButton
            }
            Spacer()
            if topics.count > 0 {
              moreLink
            }
          }
          Divider()
        }
        .padding(.top, 5)
      } else {
        ThemedSectionHeader("讨论版") {
          if isAuthenticated {
            createTopicButton
          }
          if topics.count > 0 {
            moreLink
          }
        }
        .foregroundStyle(topics.count > 0 ? .primary : .secondary)
      }
    }
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
  }
}
