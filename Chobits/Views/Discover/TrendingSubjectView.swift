import SwiftData
import SwiftUI

struct TrendingSubjectView: View {
  @Environment(\.modelContext) private var modelContext

  @State private var type: SubjectType = .anime
  @State private var width: CGFloat = 0

  func load() async {
    do {
      try await Chii.shared.loadTrendingSubjects(type: type)
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    VStack(spacing: 5) {
      HStack(alignment: .bottom) {
        Text("热门")
        Picker("Subject Type", selection: $type) {
          ForEach(SubjectType.allTypes) { st in
            Text(st.description).tag(st)
          }
        }
        .pickerStyle(.menu)
        .task(load)
        .onChange(of: type) {
          Task {
            await load()
          }
        }
        Spacer()
      }.font(.title)

      TrendingSubjectTypeView(type: type, width: width)
    }
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
  var items: [Subject] { trending.first?.items ?? [] }
  var watchers: [Int: Int] { trending.first?.watchers ?? [:] }

  init(type: SubjectType, width: CGFloat) {
    self.type = type
    self.width = width
    let descriptor = FetchDescriptor<TrendingSubject>(
      predicate: #Predicate { $0.type == type.rawValue }
    )
    self._trending = Query(descriptor)
  }

  var columnCount: Int {
    let cols = Int((width - 8) / (320 + 8))
    return cols > 0 ? cols : 1
  }

  var largeCardWidth: CGFloat {
    let cols = CGFloat(self.columnCount)
    let cw = (width - 8) / cols - 8
    if cw < 320 {
      return 320
    }
    return cw
  }

  var smallCardWidth: CGFloat {
    let cols = CGFloat(self.columnCount * 2)
    let cw = (width - 8) / cols - 8
    if cw < 160 {
      return 160
    }
    return cw
  }

  var largeColumns: [GridItem] {
    Array(repeating: GridItem(.flexible()), count: columnCount)
  }

  var smallColumns: [GridItem] {
    Array(repeating: GridItem(.flexible()), count: columnCount * 2)
  }

  var largeItems: [Subject] {
    var itemLimit = 6
    if columnCount == 2 {
      itemLimit = 10
    } else if columnCount == 3 {
      itemLimit = 12
    } else if columnCount == 4 {
      itemLimit = 12
    }
    return Array(items.prefix(itemLimit))
  }

  var smallItems: [Subject] {
    let itemLimit = columnCount * 2
    let largeCount = largeItems.count
    return Array(items.dropFirst(largeCount).prefix(itemLimit))
  }

  var body: some View {
    LazyVStack(spacing: 5) {
      if items.isEmpty {
        ProgressView()
      } else {
        LazyVGrid(columns: largeColumns, spacing: 8) {
          ForEach(largeItems) { item in
            ImageView(img: item.images?.resize(.r800))
              .imageStyle(width: largeCardWidth, height: largeCardWidth * 1.2)
              .imageType(.subject)
              .imageCaption {
                Text(item.name)
                  .multilineTextAlignment(.leading)
                  .truncationMode(.middle)
                  .lineLimit(2)
                  .font(.body)
                  .padding(8)
              }
              .imageBadge(show: watchers[item.subjectId] ?? 0 > 10) {
                Text("\(watchers[item.subjectId] ?? 0) 人关注")
                  .font(.callout)
              }
              .imageLink(item.link)
              .padding(8)
              .shadow(color: Color.black.opacity(0.2), radius: 4)
              .subjectPreview(item.slim)
          }
        }
        LazyVGrid(columns: smallColumns, spacing: 8) {
          ForEach(smallItems) { item in
            ImageView(img: item.images?.resize(.r400))
              .imageStyle(width: smallCardWidth, height: smallCardWidth * 1.3)
              .imageType(.subject)
              .imageCaption {
                Text(item.name)
                  .multilineTextAlignment(.leading)
                  .truncationMode(.middle)
                  .lineLimit(2)
                  .font(.footnote)
                  .padding(4)
              }
              .imageBadge(show: watchers[item.subjectId] ?? 0 > 10) {
                Text("\(watchers[item.subjectId] ?? 0) 人关注")
                  .font(.footnote)
              }
              .imageLink(item.link)
              .padding(8)
              .shadow(color: Color.black.opacity(0.2), radius: 4)
              .subjectPreview(item.slim)
          }
        }
      }
    }.animation(.default, value: items)
  }
}
