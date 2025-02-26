import SwiftData
import SwiftUI

struct TrendingSubjectView: View {
  @Environment(\.modelContext) private var modelContext

  @State private var width: CGFloat = 0
  @State private var loaded: Bool = false

  func load() async {
    if loaded {
      return
    }
    do {
      try await Chii.shared.loadTrendingSubjects()
      loaded = true
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    LazyVStack(spacing: 24) {
      ForEach(SubjectType.allTypes) { st in
        TrendingSubjectTypeView(type: st, width: width)
      }
    }
    .animation(.default, value: width)
    .task(load)
    .onGeometryChange(for: CGSize.self) { proxy in
      proxy.size
    } action: { newSize in
      if self.width != newSize.width {
        self.width = newSize.width
      }
    }
  }
}

struct TrendingSubjectTypeView: View {
  let type: SubjectType
  let width: CGFloat

  @Environment(\.modelContext) private var modelContext

  @Query private var trending: [TrendingSubject]
  var items: [TrendingSubjectDTO] { trending.first?.items ?? [] }

  init(type: SubjectType, width: CGFloat) {
    self.type = type
    self.width = width
    let descriptor = FetchDescriptor<TrendingSubject>(
      predicate: #Predicate { $0.type == type.rawValue }
    )
    self._trending = Query(descriptor)
  }

  var columnCount: Int {
    let count = Int(width / 320)
    return max(count, 1)
  }

  var largeCardWidth: CGFloat {
    var w = CGFloat(320)
    w = (width + 8) / CGFloat(columnCount) - 8
    return max(w, 300)
  }

  var smallCardWidth: CGFloat {
    let w = (width + 8) / CGFloat(columnCount * 2) - 8
    return max(w, 150)
  }

  var largeItems: [TrendingSubjectDTO] {
    return Array(items.prefix(columnCount))
  }

  var smallItems: [TrendingSubjectDTO] {
    return Array(items.dropFirst(largeItems.count))
  }

  var body: some View {
    VStack(spacing: 8) {
      if items.isEmpty {
        ProgressView()
      } else {
        Text("\(type.description)").font(.title)
        HStack {
          ForEach(largeItems) { item in
            ImageView(img: item.subject.images?.resize(.r800))
              .imageStyle(width: largeCardWidth, height: largeCardWidth * 1.2)
              .imageType(.subject)
              .imageCaption {
                Text(item.subject.name)
                  .multilineTextAlignment(.leading)
                  .truncationMode(.middle)
                  .lineLimit(2)
                  .font(.body)
                  .padding(8)
              }
              .imageBadge(show: item.count > 10) {
                Text("\(item.count) 人关注")
                  .font(.callout)
              }
              .imageLink(item.subject.link)
              .subjectPreview(item.subject)
          }
        }
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack {
            ForEach(smallItems) { item in
              ImageView(img: item.subject.images?.resize(.r400))
                .imageStyle(width: smallCardWidth, height: smallCardWidth * 1.3)
                .imageType(.subject)
                .imageCaption {
                  Text(item.subject.name)
                    .multilineTextAlignment(.leading)
                    .truncationMode(.middle)
                    .lineLimit(2)
                    .font(.footnote)
                    .padding(4)
                }
                .imageBadge(show: item.count > 10) {
                  Text("\(item.count) 人关注")
                    .font(.footnote)
                }
                .imageLink(item.subject.link)
                .subjectPreview(item.subject)
            }
          }
        }
      }
    }.animation(.default, value: items)
  }
}
