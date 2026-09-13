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
  let reloadToken: Int

  @AppStorage("trendingSubjectCollapseState")
  private var collapseState: TrendingSubjectCollapseState = TrendingSubjectCollapseState()
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  var body: some View {
    VStack(spacing: 24) {
      ForEach(SubjectType.allTypes) { type in
        TrendingSubjectTypeView(
          type: type,
          width: width - 16,
          reloadToken: reloadToken,
          collapseState: $collapseState
        )
      }
    }
    .padding(.horizontal, 8)
  }
}

private struct TrendingSubjectTypeView: View {
  let type: SubjectType
  let width: CGFloat
  let reloadToken: Int
  @Binding var collapseState: TrendingSubjectCollapseState

  @AppStorage("subjectImageQuality") var subjectImageQuality: ImageQuality = .high
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @State private var items: [TrendingSubjectDTO] = []
  @State private var collectionTypes: [Int: CollectionType] = [:]

  var columnCount: Int {
    let count = Int(width / 320)
    return max(count, 1)
  }

  var heroCardWidth: CGFloat {
    min(width, 480)
  }

  var heroCardHeight: CGFloat {
    heroCardWidth * type.coverAspectRatio
  }

  var smallCardWidth: CGFloat {
    let w = (width + 8) / CGFloat(columnCount * 2) - 8
    return max(w, 150)
  }

  var heroItem: TrendingSubjectDTO? {
    items.first
  }

  var smallItems: [TrendingSubjectDTO] {
    return Array(items.dropFirst())
  }

  private static func subjectIds(in items: [TrendingSubjectDTO]) -> [Int] {
    SubjectCollectionTypeResolver.sortedUniqueSubjectIds(items.map(\.subject.id))
  }

  private var isCollapsed: Bool {
    collapseState[type]
  }

  private func heroCard(item: TrendingSubjectDTO) -> some View {
    let ctype = collectionTypes[item.subject.id] ?? CollectionType.none
    return ImageView(img: item.subject.images?.resize(subjectImageQuality.largeSize))
      .imageStyle(
        width: heroCardWidth, height: heroCardHeight, cornerRadius: 12
      )
      .imageType(.subject)
      .overlay(alignment: .topLeading) {
        TrendingCollectionCapsule(ctype: ctype, subjectType: type, padding: 12)
      }
      .overlay(alignment: .bottom) {
        LinearGradient(
          gradient: Gradient(colors: [
            Color.black.opacity(0),
            Color.black.opacity(0.75),
          ]), startPoint: .top, endPoint: .bottom
        )
        .frame(height: 140)
        .clipShape(
          UnevenRoundedRectangle(bottomLeadingRadius: 12, bottomTrailingRadius: 12)
        )
        .overlay(alignment: .bottomLeading) {
          VStack(alignment: .leading, spacing: 4) {
            Text(item.subject.title(with: titlePreference))
              .font(.title3)
              .bold()
              .foregroundStyle(.white)
              .multilineTextAlignment(.leading)
              .truncationMode(.middle)
              .lineLimit(2)
              .shadow(color: .black.opacity(0.6), radius: 2, y: 1)
            if item.count > 10 {
              Text("\(item.count) 人关注")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
            }
          }
          .padding(14)
        }
      }
      .imageNavLink(item.subject.link)
      .subjectPreview(
        item.subject,
        collectionType: ctype
      ) {
        await reloadCollectionType(subjectId: item.subject.id)
      }
  }

  private var smallRow: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack {
        ForEach(smallItems) { item in
          let ctype = collectionTypes[item.subject.id] ?? CollectionType.none
          ImageView(img: item.subject.images?.resize(subjectImageQuality.mediumSize))
            .imageStyle(
              width: smallCardWidth, height: type.coverHeight(for: smallCardWidth),
              cornerRadius: 12
            )
            .imageType(.subject)
            .imageCaption(cornerRadius: 12) {
              HStack {
                VStack(alignment: .leading) {
                  Text(item.subject.title(with: titlePreference))
                    .multilineTextAlignment(.leading)
                    .truncationMode(.middle)
                    .lineLimit(2)
                    .font(.footnote)
                    .bold()
                  if item.count > 10 {
                    Text("\(item.count) 人关注")
                      .font(.caption)
                  }
                }
                Spacer(minLength: 0)
              }.padding(8)
            }
            .overlay(alignment: .topLeading) {
              TrendingCollectionCapsule(ctype: ctype, subjectType: type)
            }
            .imageNavLink(item.subject.link)
            .subjectPreview(
              item.subject,
              collectionType: ctype
            ) {
              await reloadCollectionType(subjectId: item.subject.id)
            }
        }
      }.scrollTargetLayout()
    }
    .scrollClipDisabled()
    .scrollTargetBehavior(.viewAligned)
  }

  var body: some View {
    VStack(spacing: 8) {
      TrendingSubjectTypeHeader(type: type, items: items, collapseState: $collapseState)

      if isCollapsed {
        EmptyView()
      } else if items.isEmpty {
        ProgressView()
      } else {
        if let heroItem {
          heroCard(item: heroItem)
        }
        if !smallItems.isEmpty {
          smallRow
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

private struct TrendingSubjectTypeHeader: View {
  let type: SubjectType
  let items: [TrendingSubjectDTO]
  @Binding var collapseState: TrendingSubjectCollapseState

  @AppStorage("subjectImageQuality") var subjectImageQuality: ImageQuality = .high

  private var isCollapsed: Bool {
    collapseState[type]
  }

  private var previewItems: [TrendingSubjectDTO] {
    Array(items.prefix(5))
  }

  private var collapsedCovers: some View {
    HStack(spacing: -8) {
      ForEach(Array(previewItems.enumerated()), id: \.element.id) { index, item in
        ImageView(img: item.subject.images?.resize(subjectImageQuality.mediumSize))
          .imageStyle(
            width: 22, height: 22 * type.coverAspectRatio, cornerRadius: 4
          )
          .imageType(.subject)
          .padding(1.5)
          .background(Color(uiColor: .systemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 5.5))
          .zIndex(Double(previewItems.count - index))
      }
    }
    .allowsHitTesting(false)
  }

  var body: some View {
    HStack {
      Button {
        withAnimation(.default) {
          collapseState[type].toggle()
        }
      } label: {
        HStack(spacing: 10) {
          HStack(spacing: 0) {
            Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
              .font(.headline)
              .frame(width: 28, height: 28)

            Text(type.description)
              .font(.title)
          }

          if isCollapsed, !previewItems.isEmpty {
            collapsedCovers
          }
        }
        .contentShape(Rectangle())
        .accessibilityLabel(isCollapsed ? "展开" : "收起")
      }
      .buttonStyle(.plain)

      Spacer()

      NavigationLink(value: NavDestination.subjectBrowsing(type)) {
        Text("更多 »")
      }
      .buttonStyle(.navigation)
    }
  }
}

/// Collection status shown as a floating capsule on the top-leading corner
/// of trending cards, replacing the shared circular corner badge.
private struct TrendingCollectionCapsule: View {
  let ctype: CollectionType
  let subjectType: SubjectType
  var padding: CGFloat = 8

  var body: some View {
    if ctype != .none {
      TrendingCollectionMark(ctype: ctype, subjectType: subjectType)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.black.opacity(0.45), in: Capsule())
        .padding(padding)
    }
  }
}

/// Compact collection marker shown inline in the trending card caption,
/// instead of the shared circular corner badge. White icon + status text,
/// so the state reads clearly on any artwork.
private struct TrendingCollectionMark: View {
  let ctype: CollectionType
  let subjectType: SubjectType

  var body: some View {
    if ctype != .none {
      HStack(spacing: 3) {
        Image(systemName: ctype.icon)
          .font(.caption.weight(.bold))
          .imageScale(.small)
        Text(ctype.description(subjectType))
      }
      .shadow(color: .black.opacity(0.6), radius: 1, y: 1)
    }
  }
}
