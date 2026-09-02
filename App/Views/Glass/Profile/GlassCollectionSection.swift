import SwiftUI

struct GlassSectionMoreLabel: View {
  let total: Int?

  @Environment(\.theme) private var theme

  init(total: Int?) {
    self.total = total
  }

  private var text: String {
    guard let total, total > 0 else { return "全部" }
    return "全部 \(total)"
  }

  var body: some View {
    HStack(spacing: 3) {
      Text(text)
      Image(systemName: "chevron.right")
        .font(.caption2.weight(.semibold))
    }
    .font(.caption.weight(.semibold))
    .foregroundStyle(theme.placeholder)
  }
}

struct GlassSectionCard<Content: View>: View {
  let title: String
  let total: Int?
  let destination: NavDestination?
  var insetsContent: Bool = true
  @ViewBuilder var content: Content

  @Environment(\.theme) private var theme

  var body: some View {
    CardView(padding: 0) {
      VStack(alignment: .leading, spacing: 10) {
        header
          .padding(.horizontal, 14)
        content
          .padding(.horizontal, insetsContent ? 14 : 0)
      }
      .padding(.vertical, 14)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private var header: some View {
    ThemedSectionHeader {
      Text(title)
        .foregroundStyle(theme.title)
        .lineLimit(1)
    } trailing: {
      if let destination {
        NavigationLink(value: destination) {
          GlassSectionMoreLabel(total: total)
        }
        .buttonStyle(.plain)
      } else {
        GlassSectionMoreLabel(total: total)
      }
    }
  }
}

struct GlassCoverTile: View {
  let subject: SlimSubjectDTO
  var badge: String? = nil
  var collectionType: CollectionType? = nil
  var onCollectionSaved: (() async -> Void)? = nil

  @AppStorage("titlePreference") private var titlePreference: TitlePreference = .original

  @Environment(\.theme) private var theme

  private let width: CGFloat = 82

  private var height: CGFloat {
    subject.type.coverHeight(for: width)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      ImageView(img: subject.images?.resize(.r200))
        .imageStyle(width: width, height: height, cornerRadius: theme.metrics.coverRadius)
        .imageType(.subject)
        .imageNSFW(subject.nsfw)
        .overlay(alignment: .topLeading) {
          if let badge {
            GlassCoverBadge(text: badge)
          }
        }
        .imageNavLink(subject.link)
        .subjectPreview(
          subject,
          eps: true,
          collectionType: collectionType,
          onCollectionSaved: onCollectionSaved
        )
      Text(subject.title(with: titlePreference))
        .font(.caption.weight(.semibold))
        .foregroundStyle(theme.sectionHeader)
        .lineLimit(1)
        .truncationMode(.tail)
    }
    .frame(width: width, alignment: .leading)
  }
}

struct GlassCoverBadge: View {
  let text: String

  @Environment(\.theme) private var theme

  init(text: String) {
    self.text = text
  }

  var body: some View {
    Text(text)
      .font(.caption2.weight(.bold).monospaced())
      .foregroundStyle(.white)
      .lineLimit(1)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(
        theme.maskFill,
        in: RoundedRectangle(cornerRadius: theme.metrics.badgeRadius, style: .continuous)
      )
      .padding(5)
  }
}

struct GlassCollectionChips: View {
  let subjectType: SubjectType
  let counts: [CollectionType: Int]
  @Binding var selection: CollectionType

  private var visibleTypes: [CollectionType] {
    let types = CollectionType.allTypes().filter { counts[$0, default: 0] > 0 }
    return types.isEmpty ? CollectionType.allTypes() : types
  }

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 6) {
        ForEach(visibleTypes, id: \.self) { type in
          GlassChip(
            title: type.description(subjectType),
            count: counts[type, default: 0],
            isSelected: selection == type
          ) {
            guard selection != type else { return }
            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
              selection = type
            }
          }
        }
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 2)
    }
    .scrollClipDisabled()
  }
}

struct GlassCollectionSection: View {
  let stype: SubjectType

  @State private var ctype: CollectionType = .collect
  @State private var counts: [CollectionType: Int] = [:]
  @State private var subjects: [SubjectDTO] = []

  @Environment(\.theme) private var theme

  private var total: Int {
    counts.values.reduce(0, +)
  }

  func load() async {
    do {
      let db = try await AppContext.shared.getDB()
      let fetched = try await db.fetchCollectionSubjects(
        subjectType: stype,
        collectionType: ctype,
        limit: 20,
        offset: 0
      )
      withAnimation(.default) {
        subjects = fetched
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func loadCounts() async {
    do {
      let db = try await AppContext.shared.getDB()
      let fetchedCounts = try await db.fetchCollectionCounts(subjectType: stype)
      withAnimation(.default) {
        counts = fetchedCounts
        if fetchedCounts[ctype, default: 0] == 0,
          let preferredType = CollectionType.preferredAvailableType(in: fetchedCounts)
        {
          ctype = preferredType
        }
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func reloadAfterCollectionSaved() async {
    await loadCounts()
    await load()
  }

  private func progressBadge(_ subject: SubjectDTO) -> String? {
    guard let interest = subject.interest else { return nil }
    switch subject.type {
    case .book:
      if interest.volStatus > 0 {
        return "\(interest.volStatus)卷"
      }
      guard interest.epStatus > 0 else { return nil }
      return "\(interest.epStatus)话"
    default:
      guard interest.epStatus > 0 else { return nil }
      guard subject.eps > 0 else { return "\(interest.epStatus)" }
      return "\(interest.epStatus)/\(subject.eps)"
    }
  }

  var body: some View {
    GlassSectionCard(
      title: "我的\(stype.description)",
      total: total,
      destination: NavDestination.collectionList(stype),
      insetsContent: false
    ) {
      GlassCollectionChips(subjectType: stype, counts: counts, selection: $ctype)
      covers
    }
    .onChange(of: ctype) { _, _ in
      Task {
        await load()
      }
    }
    .onAppear {
      Task {
        await loadCounts()
        await load()
      }
    }
  }

  @ViewBuilder
  private var covers: some View {
    if subjects.isEmpty {
      Text("还没有\(stype.description)收藏")
        .font(.footnote)
        .foregroundStyle(theme.tertiaryText)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    } else {
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(alignment: .top, spacing: 9) {
          ForEach(subjects) { subject in
            GlassCoverTile(
              subject: subject.slim,
              badge: progressBadge(subject),
              collectionType: ctype,
              onCollectionSaved: { await reloadAfterCollectionSaved() }
            )
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
          }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 2)
      }
      .scrollClipDisabled()
    }
  }
}
