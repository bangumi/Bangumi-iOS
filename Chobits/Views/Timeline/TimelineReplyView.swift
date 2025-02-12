import SwiftUI

struct TimelineReplyView: View {
  let item: TimelineDTO

  @AppStorage("isolationMode") var isolationMode: Bool = false

  @State private var comments: [CommentDTO] = []

  func load() async {
    if isolationMode { return }
    if !comments.isEmpty { return }
    do {
      comments = try await Chii.shared.getTimelineReplies(item.id)
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading) {
        if let user = item.user {
          HStack {
            ImageView(img: user.avatar?.large)
              .imageStyle(width: 60, height: 60)
              .imageType(.avatar)
              .imageLink(user.link)
            VStack(alignment: .leading) {
              Text(user.nickname.withLink(user.link)).font(.headline)
              Divider()
              Text(user.sign)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
          }.frame(height: 60)
          Divider()
        }
        Text(.init(item.memo.status?.tsukkomi ?? ""))
          .tint(.linkText)
          .textSelection(.enabled)
        if !isolationMode {
          Divider()
          ForEach(comments) { comment in
            CommentItemView(comment: comment, bbcode: false)
          }
        }
      }.padding(.horizontal, 8)
    }
    .navigationTitle("回复吐槽")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      Task {
        await load()
      }
    }
  }
}
