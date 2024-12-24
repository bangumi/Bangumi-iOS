import OSLog
import SwiftData
import SwiftUI

struct SubjectCommentListView: View {
  let subjectId: Int

  @State private var fetching: Bool = false
  @State private var offset: Int = 0
  @State private var exhausted: Bool = false
  @State private var loadedIdx: [Int: Bool] = [:]
  @State private var comments: [EnumerateItem<SubjectCommentDTO>] = []

  @Query private var subjects: [Subject]
  private var subject: Subject? { subjects.first }

  init(subjectId: Int) {
    self.subjectId = subjectId
    _subjects = Query(
      filter: #Predicate<Subject> {
        $0.subjectId == subjectId
      })
  }

  func fetch(limit: Int = 20) async -> [EnumerateItem<SubjectCommentDTO>] {
    fetching = true
    do {
      let resp = try await Chii.shared.getSubjectComments(subjectId, limit: limit, offset: offset)
      if resp.total < offset + limit {
        exhausted = true
      }
      let result = resp.data.enumerated().map { (idx, item) in
        EnumerateItem(idx: idx + offset, inner: item)
      }
      offset += limit
      fetching = false
      return result
    } catch {
      Notifier.shared.alert(error: error)
    }
    fetching = false
    return []
  }

  func load() async {
    offset = 0
    exhausted = false
    loadedIdx.removeAll()
    comments.removeAll()
    let items = await fetch()
    self.comments.append(contentsOf: items)
  }

  func loadNextPage(idx: Int) async {
    if exhausted {
      return
    }
    if idx != offset - 5 {
      return
    }
    if loadedIdx[idx, default: false] {
      return
    }
    loadedIdx[idx] = true
    let items = await fetch()
    self.comments.append(contentsOf: items)
  }

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading) {
        ForEach(comments, id: \.inner.self) { item in
          let comment = item.inner
          HStack(alignment: .top) {
            ImageView(img: comment.user.avatar?.large)
              .imageStyle(width: 32, height: 32)
              .imageType(.avatar)
              .imageLink(comment.user.link)
            VStack(alignment: .leading) {
              HStack {
                Text(comment.user.nickname.withLink(comment.user.link))
                  .font(.footnote)
                  .lineLimit(1)
                if comment.rate > 0 {
                  StarsView(score: Float(comment.rate), size: 10)
                }
                Text(
                  "\(comment.type.description(subject?.typeEnum)) @ \(comment.updatedAt.durationDisplay)"
                )
                .lineLimit(1)
                .font(.caption)
                .foregroundStyle(.secondary)
                Spacer()
              }
              Text(comment.comment).font(.footnote)
            }
            Spacer()
          }
          .padding(.top, 2)
          .onAppear {
            Task {
              await loadNextPage(idx: item.idx)
            }
          }
        }
        if fetching {
          HStack {
            Spacer()
            ProgressView()
            Spacer()
          }
        }
        if exhausted {
          Divider()
          HStack {
            Spacer()
            Text("没有更多了")
              .font(.footnote)
              .foregroundStyle(.secondary)
            Spacer()
          }
        }
      }.padding(.horizontal, 8)
    }
    .buttonStyle(.navLink)
    .animation(.default, value: comments)
    .navigationTitle("吐槽")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Image(systemName: "list.bullet.circle").foregroundStyle(.secondary)
      }
    }
    .onAppear {
      if comments.count > 0 {
        return
      }
      Task {
        await load()
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
      SubjectCommentListView(subjectId: subject.subjectId)
        .modelContainer(container)
    }
  }.padding()
}
