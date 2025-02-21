import SwiftUI

struct RakuenSubjectTopicView: View {
  @State private var reloader = false

  private func load(limit: Int, offset: Int) async -> PagedDTO<SubjectTopicDTO>? {
    do {
      let resp = try await Chii.shared.getTrendingSubjectTopics(limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
      return nil
    }
  }

  var body: some View {
    ScrollView {
      PageView<SubjectTopicDTO, _>(reloader: reloader, nextPageFunc: load) { topic in
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
                Spacer()
                NavigationLink(value: NavDestination.subject(topic.subject.id)) {
                  Text(topic.subject.name)
                    .font(.footnote)
                }.buttonStyle(.plain)
              }
            }
            Spacer()
          }
        }
      }.padding(8)
    }
    .navigationTitle("条目讨论")
    .navigationBarTitleDisplayMode(.inline)
    .refreshable {
      reloader.toggle()
    }
  }
}
