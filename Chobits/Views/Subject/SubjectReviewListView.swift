import OSLog
import SwiftData
import SwiftUI

struct SubjectReviewListView: View {
  let subjectId: Int

  @State private var fetching: Bool = false
  @State private var offset: Int = 0
  @State private var exhausted: Bool = false
  @State private var loadedIdx: [Int: Bool] = [:]
  @State private var reviews: [EnumerateItem<SubjectReviewDTO>] = []

  func fetch(limit: Int = 10) async -> [EnumerateItem<SubjectReviewDTO>] {
    fetching = true
    do {
      let resp = try await Chii.shared.getSubjectReviews(subjectId, limit: limit, offset: offset)
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
    reviews.removeAll()
    let items = await fetch()
    self.reviews.append(contentsOf: items)
  }

  func loadNextPage(idx: Int) async {
    if exhausted { return }
    if idx != offset - 3 { return }
    if loadedIdx[idx, default: false] { return }
    loadedIdx[idx] = true
    let items = await fetch()
    self.reviews.append(contentsOf: items)
  }

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading) {
        ForEach(reviews, id: \.inner.self) { item in
          SubjectReviewItemView(item: item.inner)
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
    .animation(.default, value: reviews)
    .navigationTitle("评论")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Image(systemName: "list.bullet.circle").foregroundStyle(.secondary)
      }
    }
    .onAppear {
      if reviews.count > 0 { return }
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
      SubjectReviewListView(subjectId: subject.subjectId)
    }.padding()
  }.modelContainer(container)
}
