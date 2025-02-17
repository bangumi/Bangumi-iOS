import BBCode
import SwiftData
import SwiftUI

struct BlogView: View {
  let blogId: Int

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("isolationMode") var isolationMode: Bool = false

  @State private var refreshed: Bool = false
  @State private var blog: BlogEntryDTO?
  @State private var subjects: [SlimSubjectDTO] = []
  @State private var comments: [CommentDTO] = []

  var title: String {
    guard let blog = blog else {
      return "日志"
    }
    return blog.title
  }

  var shareLink: URL {
    URL(string: "https://\(shareDomain.rawValue)/blog/\(blogId)")!
  }

  func load() async {
    do {
      blog = try await Chii.shared.getBlogEntry(blogId)
      subjects = try await Chii.shared.getBlogSubjects(blogId)
      if !isolationMode {
        comments = try await Chii.shared.getBlogComments(blogId)
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    Section {
      if let blog = blog {
        ScrollView {
          VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 5) {
              UserSmallView(user: blog.user)
                .padding(.top, 8)
              Text(blog.title)
                .font(.title3)
                .bold()
              HStack {
                Text(blog.createdAt.datetimeDisplay)
                  .font(.caption)
                  .foregroundColor(.secondary)
                Spacer()
                Menu {
                  ForEach(subjects) { subject in
                    NavigationLink(value: NavDestination.subject(subject.id)) {
                      HStack {
                        ImageView(img: subject.images?.small)
                          .imageStyle(width: 32, height: 32)
                          .imageType(.subject)
                        Text(subject.title)
                      }
                    }
                  }
                } label: {
                  Text(subjects.isEmpty ? "" : "关联条目+")
                    .font(.caption)
                    .foregroundStyle(.accent)
                }.disabled(subjects.isEmpty)
              }
              Divider()
              BBCodeView(blog.content)
                .textSelection(.enabled)
                .padding(.top, 8)
            }

            /// comments
            if !isolationMode {
              Divider()
              LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(Array(zip(comments.indices, comments)), id: \.1) { idx, comment in
                  CommentItemView(type: .blog(blogId), comment: comment, idx: idx)
                  if comment.id != comments.last?.id {
                    Divider()
                  }
                }
              }
            }
          }.padding(.horizontal, 8)
        }
      } else if refreshed {
        NotFoundView()
      } else {
        ProgressView()
      }
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          ShareLink(item: shareLink) {
            Label("分享", systemImage: "square.and.arrow.up")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }
    .onAppear {
      Task {
        await load()
      }
    }
  }
}
