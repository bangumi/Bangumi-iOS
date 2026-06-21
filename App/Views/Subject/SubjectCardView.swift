import SwiftUI

struct SubjectTinyView: View {
  let subject: SlimSubjectDTO

  var title: String {
    if subject.nameCN.isEmpty {
      return subject.name
    } else {
      return subject.nameCN
    }
  }

  var body: some View {
    BorderView(color: .secondary.opacity(0.2), padding: 4, paddingRatio: 1, cornerRadius: 8) {
      HStack {
        ImageView(img: subject.images?.small)
          .imageStyle(width: 32, height: 32)
          .imageType(.subject)
        VStack(alignment: .leading) {
          Text(title)
            .lineLimit(1)
        }
        Spacer(minLength: 0)
      }
    }
    .background(.secondary.opacity(0.01))
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .frame(height: 40)
    .subjectPreview(subject)
  }
}

struct SubjectSmallView: View {
  let subject: SlimSubjectDTO

  var title: String {
    if subject.nameCN.isEmpty {
      return subject.name
    } else {
      return subject.nameCN
    }
  }

  var ratingLine: Text {
    guard let rating = subject.rating else {
      return Text("")
    }
    var text: [Text] = []
    if rating.rank > 0, rating.rank < 1000 {
      text.append(Text("#\(rating.rank) "))
    }
    if rating.score > 0 {
      let img = Image(systemName: "star.fill")
      text.append(Text("\(img)").font(.system(size: 10)).baselineOffset(1))
      let score = String(format: "%.1f", rating.score)
      text.append(Text(" \(score)"))
    }
    if rating.total > 10 {
      text.append(Text(" (\(rating.total))"))
    }
    return text.reduce(Text(""), +)
  }

  var body: some View {
    BorderView(color: .secondary.opacity(0.2), padding: 4, paddingRatio: 1, cornerRadius: 8) {
      HStack {
        ImageView(img: subject.images?.resize(.r200))
          .imageStyle(width: 60, height: 72)
          .imageType(.subject)
          .imageNSFW(subject.nsfw)
        VStack(alignment: .leading) {
          Text(title)
          Text(subject.info ?? "")
            .font(.footnote)
            .foregroundStyle(.secondary)
          ratingLine
            .font(.footnote)
            .foregroundStyle(.secondary)
        }.lineLimit(1)
        Spacer(minLength: 0)
      }
    }
    .background(.secondary.opacity(0.01))
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .frame(height: 80)
    .subjectPreview(subject, eps: true)
  }
}

struct SubjectCollectionTileView: View {
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  let subject: SlimSubjectDTO
  var collectionType: CollectionType? = nil
  var onCollectionSaved: (() async -> Void)? = nil
  let imageWidth: CGFloat = 80

  var imageHeight: CGFloat {
    subject.type.coverHeight(for: imageWidth)
  }

  var body: some View {
    VStack {
      ImageView(img: subject.images?.resize(.r200))
        .imageStyle(width: imageWidth, height: imageHeight)
        .imageType(.subject)
        .imageNavLink(subject.link)
        .subjectPreview(
          subject,
          collectionType: collectionType,
          onCollectionSaved: onCollectionSaved
        )
        .shadow(radius: 2)
      Text(subject.title(with: titlePreference))
        .font(.caption2)
        .lineLimit(2, reservesSpace: true)
        .multilineTextAlignment(.leading)
    }
    .frame(width: imageWidth + 4)
  }
}

struct CollectionTypeChipsView: View {
  let subjectType: SubjectType
  let counts: [CollectionType: Int]
  @Binding var selection: CollectionType

  private var visibleTypes: [CollectionType] {
    let types = CollectionType.allTypes().filter { counts[$0, default: 0] > 0 }
    return types.isEmpty ? CollectionType.allTypes() : types
  }

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(alignment: .bottom, spacing: 2) {
        ForEach(visibleTypes, id: \.self) { type in
          let borderColor =
            selection == type
            ? Color.linkText
            : Color.secondary.opacity(0.2)
          BorderView(color: borderColor, padding: 3, cornerRadius: 16) {
            Text("\(type.description(subjectType)) \(counts[type, default: 0])")
              .lineLimit(1)
              .font(.footnote)
              .foregroundStyle(.linkText)
          }
          .padding(1)
          .onTapGesture {
            guard selection != type else { return }
            withAnimation(.default) {
              selection = type
            }
          }
        }
      }
    }
    .scrollClipDisabled()
  }
}

struct CollectionTypeSegmentedPickerView: View {
  let subjectType: SubjectType
  let counts: [CollectionType: Int]
  @Binding var selection: CollectionType

  var body: some View {
    Picker("CollectionType", selection: $selection.animated()) {
      ForEach(CollectionType.allTypes()) { type in
        Text("\(type.description(subjectType))(\(counts[type, default: 0]))").tag(type)
      }
    }
    .pickerStyle(.segmented)
    .padding(.horizontal, 8)
  }
}

struct SubjectCollectionSectionView: View {
  let title: String
  let destination: NavDestination
  let subjectType: SubjectType
  let counts: [CollectionType: Int]
  @Binding var selection: CollectionType
  let subjects: [SlimSubjectDTO]
  let refreshing: Bool
  var collectionType: CollectionType? = nil
  var onCollectionSaved: (() async -> Void)? = nil

  private let tileSpacing: CGFloat = 8
  private let headerDividerSpacing: CGFloat = 2
  private let contentInset: CGFloat = 2

  var body: some View {
    VStack(alignment: .leading, spacing: tileSpacing) {
      headerAndDivider
      content
    }
  }

  private var headerAndDivider: some View {
    VStack(alignment: .leading, spacing: headerDividerSpacing) {
      header
        .padding(.top, 8)
      Divider()
    }
  }

  private var header: some View {
    HStack(alignment: .bottom, spacing: 2) {
      NavigationLink(value: destination) {
        Text(title).font(.title3)
      }
      .buttonStyle(.navigation)
      .padding(.horizontal, 4)

      CollectionTypeChipsView(subjectType: subjectType, counts: counts, selection: $selection)

      Spacer(minLength: 0)
    }
  }

  @ViewBuilder
  private var content: some View {
    if refreshing {
      HStack {
        Spacer()
        ProgressView().padding()
        Spacer()
      }
    } else {
      ScrollView(.horizontal, showsIndicators: false) {
        LazyHStack(alignment: .top, spacing: tileSpacing) {
          ForEach(subjects) { subject in
            SubjectCollectionTileView(
              subject: subject,
              collectionType: collectionType,
              onCollectionSaved: onCollectionSaved
            )
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
          }
        }
        .padding(.horizontal, contentInset)
        .padding(.bottom, contentInset)
      }
      .scrollClipDisabled()
    }
  }
}

struct SubjectCollectionRowContentView: View {
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  let subject: SlimSubjectDTO
  let isPrivate: Bool
  let showsCollectionEditButton: Bool
  var onCollectionSaved: (() async -> Void)?

  @State private var showCollectionBox = false

  private let imageWidth: CGFloat = 60

  private var imageHeight: CGFloat {
    subject.type.coverHeight(for: imageWidth)
  }

  init(
    subject: SlimSubjectDTO,
    isPrivate: Bool = false,
    showsCollectionEditButton: Bool = false,
    onCollectionSaved: (() async -> Void)? = nil
  ) {
    self.subject = subject
    self.isPrivate = isPrivate
    self.showsCollectionEditButton = showsCollectionEditButton
    self.onCollectionSaved = onCollectionSaved
  }

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      ImageView(img: subject.images?.resize(.r200))
        .imageStyle(width: imageWidth, height: imageHeight)
        .imageType(.subject)
        .imageNavLink(subject.link)
      VStack(alignment: .leading) {
        Text(subject.title(with: titlePreference).withLink(subject.link))
          .lineLimit(1)
        if let subtitle = subject.subtitle(with: titlePreference) {
          Text(subtitle)
            .lineLimit(1)
            .font(.caption)
            .foregroundStyle(.secondary.opacity(0.8))
        }
        Text(subject.info ?? "")
          .lineLimit(1)
          .font(.footnote)
          .foregroundStyle(.secondary)
        Spacer()
        if let interest = subject.interest {
          HStack {
            if isPrivate {
              Image(systemName: "lock.fill").foregroundStyle(.accent)
            }
            Text(interest.updatedAt.datetimeDisplay)
              .foregroundStyle(.secondary)
              .lineLimit(1)
            Spacer()
            if interest.rate > 0 {
              StarsView(score: Float(interest.rate), size: 12)
            }
          }.font(.footnote)
          if !interest.comment.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
              Divider()
              Text(interest.comment)
                .padding(2)
                .font(.footnote)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
            }
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      if showsCollectionEditButton {
        Button {
          showCollectionBox = true
        } label: {
          Image(systemName: "pencil")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .accessibilityLabel("编辑收藏")
      }
    }
    .buttonStyle(.navigation)
    .frame(minHeight: 60)
    .padding(2)
    .clipShape(RoundedRectangle(cornerRadius: 10))
    .sheet(isPresented: $showCollectionBox) {
      SubjectCollectionBoxView(subjectId: subject.id, onSaved: onCollectionSaved)
        .presentationDragIndicator(.visible)
    }
  }
}

extension CollectionType {
  static func preferredAvailableType(in counts: [CollectionType: Int]) -> CollectionType? {
    for type in timelineTypes() where counts[type, default: 0] > 0 {
      return type
    }
    return allTypes().first { counts[$0, default: 0] > 0 }
  }
}

struct SubjectCardView: View {
  let subject: SlimSubjectDTO

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  var ratingLine: Text {
    guard let rating = subject.rating else {
      return Text("")
    }
    var text: [Text] = []
    if rating.rank > 0, rating.rank < 1000 {
      text.append(Text("#\(rating.rank) "))
    }
    if rating.score > 0 {
      let img = Image(systemName: "star.fill")
      text.append(Text("\(img)").foregroundStyle(.orange).baselineOffset(1))
      let score = String(format: "%.1f", rating.score)
      text.append(Text(" \(score)"))
    }
    if rating.total > 10 {
      text.append(Text(" (\(rating.total)人评分)"))
    }
    return text.reduce(Text(""), +)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      HStack(alignment: .top) {
        ImageView(img: subject.images?.resize(.r200))
          .imageStyle(width: 80, height: 108, cornerRadius: 16)
          .imageType(.subject)
          .imageNSFW(subject.nsfw)
        VStack(alignment: .leading) {
          Text(subject.title(with: titlePreference))
            .font(.headline)
            .lineLimit(1)
          if let subtitle = subject.subtitle(with: titlePreference) {
            Text(subtitle)
              .font(.subheadline)
              .lineLimit(1)
          }
          Spacer()
          Text(subject.info ?? "")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(2)
          Spacer()
          ratingLine
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        Spacer(minLength: 0)
      }
    }
  }
}

extension View {
  func subjectPreview(
    _ subject: SlimSubjectDTO,
    eps: Bool = false,
    collectionType: CollectionType? = nil,
    onCollectionSaved: (() async -> Void)? = nil
  ) -> some View {
    modifier(
      SubjectPreviewModifier(
        subject: subject,
        eps: eps,
        collectionType: collectionType,
        onCollectionSaved: onCollectionSaved
      )
    )
  }
}

private struct SubjectPreviewModifier: ViewModifier {
  let subject: SlimSubjectDTO
  let eps: Bool
  let collectionType: CollectionType?
  let onCollectionSaved: (() async -> Void)?

  @AppStorage("isAuthenticated") private var isAuthenticated: Bool = false
  @State private var showCollectionBox = false

  private var showsCollectionAction: Bool {
    guard let collectionType else { return false }
    return isAuthenticated || collectionType != CollectionType.none
  }

  private var collectionActionTitle: String {
    collectionType == CollectionType.none ? "收藏" : "修改收藏"
  }

  private var collectionActionIcon: String {
    collectionType == CollectionType.none ? "plus" : "square.and.pencil"
  }

  func body(content: Content) -> some View {
    content
      .contextMenu {
        NavigationLink(value: NavDestination.subject(subject.id)) {
          Label("查看详情", systemImage: "magnifyingglass")
        }
        if eps, subject.type == .anime || subject.type == .real {
          NavigationLink(value: NavDestination.episodeList(subject.id)) {
            Label("章节列表", systemImage: "list.bullet")
          }
        }
        if showsCollectionAction {
          Button {
            showCollectionBox = true
          } label: {
            Label(collectionActionTitle, systemImage: collectionActionIcon)
          }
          .disabled(!isAuthenticated)
        }
      } preview: {
        SubjectCardView(subject: subject)
          .padding()
          .frame(idealWidth: 360)
      }
      .sheet(isPresented: $showCollectionBox) {
        SubjectCollectionBoxView(subjectId: subject.id, onSaved: onCollectionSaved)
      }
  }
}

enum SubjectCollectionTypeResolver {
  static func load(subjectIds: [Int]) async throws -> [Int: CollectionType] {
    guard !subjectIds.isEmpty else { return [:] }
    let db = try await AppContext.shared.getDB()
    return try await db.getCollectionTypes(subjectIds: subjectIds)
  }

  static func sortedUniqueSubjectIds(_ subjectIds: [Int]) -> [Int] {
    Array(Set(subjectIds)).sorted()
  }
}
