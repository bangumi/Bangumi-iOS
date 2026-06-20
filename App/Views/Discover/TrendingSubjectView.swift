import Foundation
import OSLog
import SwiftUI

private struct TrendingSubjectCollapseState: Equatable, RawRepresentable {
  typealias RawValue = String

  private var collapsedTypeValues: Set<Int> = []

  subscript(type: SubjectType) -> Bool {
    get {
      collapsedTypeValues.contains(type.rawValue)
    }
    set {
      if newValue {
        collapsedTypeValues.insert(type.rawValue)
      } else {
        collapsedTypeValues.remove(type.rawValue)
      }
    }
  }

  var rawValue: String {
    let dict: [String: Any] = [
      "collapsedTypes": collapsedTypeValues.sorted()
    ]
    guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys]),
      let json = String(data: data, encoding: .utf8)
    else {
      return "{}"
    }
    return json
  }

  init?(rawValue: String) {
    guard !rawValue.isEmpty else {
      self.init()
      return
    }
    guard let data = rawValue.data(using: .utf8),
      let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      self.init()
      return
    }
    let rawTypes = dict["collapsedTypes"] as? [Any] ?? []
    self.init()
    self.collapsedTypeValues = Set(rawTypes.compactMap(Self.decodeTypeValue))
  }

  init() {}

  private static func decodeTypeValue(_ value: Any) -> Int? {
    if let value = value as? Int {
      return value
    }
    if let value = value as? String {
      return Int(value)
    }
    if let value = value as? NSNumber {
      return value.intValue
    }
    return nil
  }
}

struct TrendingSubjectView: View {
  let width: CGFloat

  @AppStorage("trendingSubjectCollapseState")
  private var collapseState: TrendingSubjectCollapseState = TrendingSubjectCollapseState()
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @State private var loaded: Bool = false
  @State private var reloader: Bool = false

  func load() async {
    if loaded {
      return
    }
    do {
      try await DiscoveryRepository.loadTrendingSubjects()
      withAnimation(.default) {
        loaded = true
        reloader.toggle()
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    VStack(spacing: 24) {
      ForEach(SubjectType.allTypes) { type in
        TrendingSubjectTypeView(
          type: type, width: width - 16, reloader: reloader, collapseState: $collapseState)
      }
    }
    .padding(.horizontal, 8)
    .task(load)
  }
}

private struct TrendingSubjectTypeView: View {
  let type: SubjectType
  let width: CGFloat
  let reloader: Bool
  @Binding var collapseState: TrendingSubjectCollapseState

  @AppStorage("subjectImageQuality") var subjectImageQuality: ImageQuality = .high
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @State private var items: [TrendingSubjectDTO] = []
  @State private var collectionTypes: [Int: CollectionType] = [:]

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

  private static func subjectIds(in items: [TrendingSubjectDTO]) -> [Int] {
    SubjectCollectionTypeResolver.sortedUniqueSubjectIds(items.map(\.subject.id))
  }

  private var isCollapsed: Bool {
    collapseState[type]
  }

  var body: some View {
    VStack(spacing: 8) {
      TrendingSubjectTypeHeader(type: type, collapseState: $collapseState)

      if isCollapsed {
        EmptyView()
      } else if items.isEmpty {
        ProgressView()
      } else {
        HStack {
          ForEach(largeItems) { item in
            ImageView(img: item.subject.images?.resize(subjectImageQuality.largeSize))
              .imageStyle(width: largeCardWidth, height: type.coverHeight(for: largeCardWidth))
              .imageType(.subject)
              .imageCaption {
                HStack {
                  VStack(alignment: .leading) {
                    if item.count > 10 {
                      Text("\(item.count) 人关注")
                        .font(.caption)
                    }
                    Text(item.subject.title(with: titlePreference))
                      .multilineTextAlignment(.leading)
                      .truncationMode(.middle)
                      .lineLimit(2)
                      .font(.body)
                      .bold()
                  }
                  Spacer(minLength: 0)
                }.padding(8)
              }
              .imageCollectionStatus(
                ctype: collectionTypes[item.subject.id] ?? CollectionType.none
              )
              .imageNavLink(item.subject.link)
              .subjectPreview(
                item.subject,
                collectionType: collectionTypes[item.subject.id] ?? CollectionType.none
              ) {
                await reloadCollectionType(subjectId: item.subject.id)
              }
          }
        }
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack {
            ForEach(smallItems) { item in
              ImageView(img: item.subject.images?.resize(subjectImageQuality.mediumSize))
                .imageStyle(width: smallCardWidth, height: type.coverHeight(for: smallCardWidth))
                .imageType(.subject)
                .imageCaption {
                  HStack {
                    VStack(alignment: .leading) {
                      if item.count > 10 {
                        Text("\(item.count) 人关注")
                          .font(.caption)
                      }
                      Text(item.subject.title(with: titlePreference))
                        .multilineTextAlignment(.leading)
                        .truncationMode(.middle)
                        .lineLimit(2)
                        .font(.footnote)
                        .bold()
                    }
                    Spacer(minLength: 0)
                  }.padding(4)
                }
                .imageCollectionStatus(
                  ctype: collectionTypes[item.subject.id] ?? CollectionType.none
                )
                .imageNavLink(item.subject.link)
                .subjectPreview(
                  item.subject,
                  collectionType: collectionTypes[item.subject.id] ?? CollectionType.none
                ) {
                  await reloadCollectionType(subjectId: item.subject.id)
                }
            }
          }.scrollTargetLayout()
        }
        .scrollClipDisabled()
        .scrollTargetBehavior(.viewAligned)
      }
    }
    .task(id: "\(type.rawValue)-\(reloader)") {
      await loadCached()
    }
    .onReceive(
      NotificationCenter.default.publisher(for: ProgressSubjectInvalidation.notificationName),
      perform: handleSubjectInvalidation
    )
  }

  private func loadCached() async {
    do {
      let db = try await AppContext.shared.getDB()
      let fetchedItems = try await db.fetchTrendingSubjects(type: type)
      let fetchedCollectionTypes: [Int: CollectionType]
      do {
        fetchedCollectionTypes = try await SubjectCollectionTypeResolver.load(
          subjectIds: Self.subjectIds(in: fetchedItems)
        )
      } catch {
        Logger.app.error("Failed to load trending collection types: \(error)")
        fetchedCollectionTypes = [:]
      }
      withAnimation(.default) {
        items = fetchedItems
        collectionTypes = fetchedCollectionTypes
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func reloadCollectionType(subjectId: Int) async {
    do {
      let fetchedCollectionTypes = try await SubjectCollectionTypeResolver.load(
        subjectIds: [subjectId]
      )
      withAnimation(.default) {
        collectionTypes[subjectId] = fetchedCollectionTypes[subjectId] ?? CollectionType.none
      }
    } catch {
      Logger.app.error("Failed to load trending collection type: \(error)")
    }
  }

  private func handleSubjectInvalidation(_ notification: Notification) {
    guard let subjectId = ProgressSubjectInvalidation.subjectId(from: notification),
      Self.subjectIds(in: items).contains(subjectId)
    else { return }
    Task {
      await reloadCollectionType(subjectId: subjectId)
    }
  }
}

private struct TrendingSubjectTypeHeader: View {
  let type: SubjectType
  @Binding var collapseState: TrendingSubjectCollapseState

  private var isCollapsed: Bool {
    collapseState[type]
  }

  var body: some View {
    HStack {
      Button {
        withAnimation(.default) {
          collapseState[type].toggle()
        }
      } label: {
        Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
          .font(.headline)
          .frame(width: 28, height: 28)
          .contentShape(Rectangle())
          .accessibilityLabel(isCollapsed ? "展开" : "收起")
      }
      .buttonStyle(.plain)

      Text(type.description)
        .font(.title)

      Spacer()

      NavigationLink(value: NavDestination.subjectBrowsing(type)) {
        Text("更多 »")
      }
      .buttonStyle(.navigation)
    }
  }
}
