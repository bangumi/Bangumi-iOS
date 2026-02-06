import BBCode
import SwiftUI

struct TimelineView: View {
  let item: TimelineDTO

  @State private var comments: [CommentDTO] = []
  @State private var loadingComments: Bool = false
  @State private var showCommentBox: Bool = false
  @State private var showReportView: Bool = false

  func load() async {
    do {
      loadingComments = true
      comments = try await Chii.shared.getTimelineReplies(item.id)
      loadingComments = false
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 8) {
        CardView {
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              if let user = item.user {
                ImageView(img: user.avatar?.large)
                  .imageStyle(width: 20, height: 20)
                  .imageType(.avatar)
                  .imageLink(user.link)
                Text(user.nickname.withLink(user.link)).font(.headline)
              }
              Spacer()
              Text(item.createdAt.datetimeDisplay)
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            Divider()
            BBCodeView(item.memo.status?.tsukkomi ?? "")
              .tint(.linkText)
              .textSelection(.enabled)
          }
        }

        LazyVStack(alignment: .leading, spacing: 8) {
          if loadingComments {
            HStack {
              Spacer()
              ProgressView()
              Spacer()
            }
          }
          ForEach(Array(zip(comments.indices, comments)), id: \.1) { idx, comment in
            CommentItemView(type: .timeline(item.id), comment: comment, idx: idx)
            if comment.id != comments.last?.id {
              Divider()
            }
          }
        }
      }.padding(.horizontal, 8)
    }
    .task(load)
    .refreshable {
      Task {
        await load()
      }
    }
    .navigationTitle("吐槽")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          Button {
            showCommentBox = true
          } label: {
            Label("回复", systemImage: "plus.bubble")
          }
          Divider()
          Button {
            showReportView = true
          } label: {
            Label("报告疑虑", systemImage: "exclamationmark.triangle")
          }
        } label: {
          Image(systemName: "ellipsis")
        }
      }
    }
    .sheet(isPresented: $showCommentBox) {
      CreateCommentBoxSheet(type: .timeline(item.id)) {
        Task { await load() }
      }
    }
    .sheet(isPresented: $showReportView) {
      ReportSheet(
        reportType: .timeline, itemId: item.id, itemTitle: "吐槽 #\(item.id)", user: item.user)
    }
  }
}
