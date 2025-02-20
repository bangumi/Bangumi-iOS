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
  @State private var showSubjects: Bool = false
  @State private var comments: [CommentDTO] = []
  @State private var loadingComments: Bool = false

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
        loadingComments = true
        comments = try await Chii.shared.getBlogComments(blogId)
        loadingComments = false
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
                Button {
                  showSubjects = true
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
            .sheet(isPresented: $showSubjects) {
              ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                  Text("关联条目")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 16)
                  HStack {
                    Button("关闭", role: .cancel) {
                      showSubjects = false
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                  }
                  ForEach(subjects) { subject in
                    SubjectSmallView(subject: subject)
                  }
                }.padding(.horizontal, 8)
              }.presentationDetents([.medium])
            }

            /// comments
            if !isolationMode {
              Divider()
              LazyVStack(alignment: .leading, spacing: 8) {
                if loadingComments {
                  ProgressView()
                }
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
