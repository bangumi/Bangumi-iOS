import Foundation
import OSLog
import SwiftUI

private struct GlassTrendingCollapseState: Equatable, RawRepresentable {
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

struct GlassTrendingSection: View {
  let width: CGFloat
  let reloadToken: Int

  @AppStorage("trendingSubjectCollapseState")
  private var collapseState: GlassTrendingCollapseState = GlassTrendingCollapseState()

  @Environment(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      ForEach(SubjectType.allTypes) { type in
        GlassTrendingTypeSection(
          type: type,
          width: width - theme.metrics.screenPadding * 2,
          reloadToken: reloadToken,
          collapseState: $collapseState
        )
      }
    }
    .padding(.top, 10)
  }
}

private struct GlassTrendingTypeSection: View {
  let type: SubjectType
  let width: CGFloat
  let reloadToken: Int
  @Binding var collapseState: GlassTrendingCollapseState

  @AppStorage("subjectImageQuality") var subjectImageQuality: ImageQuality = .high
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Environment(\.theme) private var theme

  @State private var items: [TrendingSubjectDTO] = []
  @State private var collectionTypes: [Int: CollectionType] = [:]

  private static let gridSpacing: CGFloat = 10
  private static let largeCoverHeight: CGFloat = 150
  private static let smallCoverWidth: CGFloat = 74
  private static let smallCoverHeight: CGFloat = 103

  private var columnCount: Int {
    max(Int(width / 260), 2)
  }

  private var largeCardWidth: CGFloat {
    let total = width - Self.gridSpacing * CGFloat(columnCount - 1)
    return max(total / CGFloat(columnCount), 120)
  }

  private var largeCoverWidth: CGFloat {
    max(largeCardWidth - theme.metrics.cardPadding * 2, 60)
  }

  private var largeItems: [TrendingSubjectDTO] {
    Array(items.prefix(columnCount))
  }

  private var smallItems: [TrendingSubjectDTO] {
    Array(items.dropFirst(largeItems.count))
  }

  private var isCollapsed: Bool {
    collapseState[type]
  }

  private static func subjectIds(in items: [TrendingSubjectDTO]) -> [Int] {
    SubjectCollectionTypeResolver.sortedUniqueSubjectIds(items.map(\.subject.id))
  }

  private func toggle() {
    withAnimation(.default) {
      collapseState[type].toggle()
    }
  }

  private var titleButton: some View {
    Button(action: toggle) {
      HStack(spacing: 6) {
        Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
          .font(.caption.weight(.bold))
          .foregroundStyle(isCollapsed ? theme.tertiaryText : theme.accent)
        Text("热门\(type.description)")
          .font(.subheadline.weight(.heavy))
          .foregroundStyle(isCollapsed ? theme.secondaryText : theme.sectionHeader)
      }
      .contentShape(Rectangle())
      .accessibilityLabel(isCollapsed ? "展开" : "收起")
    }
    .buttonStyle(.plain)
  }

  private var moreLink: some View {
    NavigationLink(value: NavDestination.subjectBrowsing(type)) {
      GlassMoreLabel(title: "更多 »")
    }
    .buttonStyle(.plain)
  }

  private var collapsedRow: some View {
    CardView(padding: 12, role: .embed) {
      HStack(alignment: .firstTextBaseline, spacing: 6) {
        titleButton
        Spacer(minLength: 0)
        moreLink
      }
    }
  }

  private var largeGrid: some View {
    LazyVGrid(
      columns: Array(
        repeating: GridItem(.flexible(), spacing: Self.gridSpacing), count: columnCount),
      spacing: Self.gridSpacing
    ) {
      ForEach(largeItems) { item in
        let ctype = collectionTypes[item.subject.id] ?? CollectionType.none
        NavigationLink(value: NavDestination.subject(item.subject.id, zoom: true)) {
          CardView(padding: theme.metrics.cardPadding) {
            VStack(alignment: .leading, spacing: 8) {
              ImageView(img: item.subject.images?.resize(subjectImageQuality.largeSize))
                .imageStyle(
                  width: largeCoverWidth, height: Self.largeCoverHeight, contentMode: .fill
                )
                .imageType(.subject)
                .overlay(alignment: .topTrailing) {
                  GlassCollectionBadge(type: ctype, subjectType: item.subject.type)
                    .padding(6)
                }
              VStack(alignment: .leading, spacing: 3) {
                Text(item.subject.title(with: titlePreference))
                  .font(.footnote.weight(.bold))
                  .foregroundStyle(theme.cardTitle)
                  .multilineTextAlignment(.leading)
                  .truncationMode(.middle)
                  .lineLimit(2)
                if item.count > 10 {
                  Text("\(glassCompactCount(item.count)) 人关注")
                    .font(.caption2.weight(.semibold).monospaced())
                    .foregroundStyle(theme.tertiaryText)
                }
              }
              .frame(maxWidth: .infinity, alignment: .leading)
            }
          }
        }
        .buttonStyle(.plain)
        .zoomSource(ZoomNavigationID(type: .subject, id: item.subject.id))
        .subjectPreview(item.subject, collectionType: ctype) {
          await reloadCollectionType(subjectId: item.subject.id)
        }
      }
    }
  }

  private var smallRow: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(alignment: .top, spacing: Self.gridSpacing) {
        ForEach(smallItems) { item in
          let ctype = collectionTypes[item.subject.id] ?? CollectionType.none
          VStack(alignment: .leading, spacing: 4) {
            ImageView(img: item.subject.images?.resize(subjectImageQuality.mediumSize))
              .imageStyle(width: Self.smallCoverWidth, height: Self.smallCoverHeight)
              .imageType(.subject)
              .overlay(alignment: .topTrailing) {
                GlassCollectionBadge(type: ctype, subjectType: item.subject.type)
                  .padding(4)
              }
              .imageNavLink(item.subject.link)
              .subjectPreview(item.subject, collectionType: ctype) {
                await reloadCollectionType(subjectId: item.subject.id)
              }
            Text(item.subject.title(with: titlePreference))
              .font(.caption2.weight(.semibold))
              .foregroundStyle(theme.cardTitle)
              .multilineTextAlignment(.leading)
              .truncationMode(.middle)
              .lineLimit(2)
            if item.count > 10 {
              Text("\(glassCompactCount(item.count)) 人关注")
                .font(.caption2.weight(.semibold).monospaced())
                .foregroundStyle(theme.tertiaryText)
                .lineLimit(1)
            }
          }
          .frame(width: Self.smallCoverWidth, alignment: .leading)
        }
      }.scrollTargetLayout()
    }
    .scrollClipDisabled()
    .scrollTargetBehavior(.viewAligned)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      if isCollapsed {
        collapsedRow
      } else {
        ThemedSectionHeader {
          titleButton
        } trailing: {
          moreLink
        }
        if items.isEmpty {
          ProgressView()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        } else {
          largeGrid
          if !smallItems.isEmpty {
            smallRow
          }
        }
      }
    }
    .task(id: "\(type.rawValue)-\(reloadToken)") {
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
