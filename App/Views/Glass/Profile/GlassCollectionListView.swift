import SwiftUI

struct GlassSubjectCollectionRow: View {
  let subject: SlimSubjectDTO
  var isPrivate: Bool = false
  var showsCollectionEditButton: Bool = false
  var onCollectionSaved: (() async -> Void)? = nil

  @AppStorage("titlePreference") private var titlePreference: TitlePreference = .original

  @State private var showCollectionBox = false

  @Environment(\.theme) private var theme

  private let imageWidth: CGFloat = 62

  private var imageHeight: CGFloat {
    subject.type.coverHeight(for: imageWidth)
  }

  private var titleText: AttributedString {
    subject.title(with: titlePreference).withLink(subject.link, linkColor: theme.cardTitle)
  }

  var body: some View {
    CardView(padding: 12) {
      HStack(alignment: .top, spacing: 12) {
        ImageView(img: subject.images?.resize(.r200))
          .imageStyle(
            width: imageWidth, height: imageHeight, cornerRadius: theme.metrics.coverRadius
          )
          .imageType(.subject)
          .imageNSFW(subject.nsfw)
          .imageNavLink(subject.link)
        details
        if showsCollectionEditButton {
          GlassGhostIconButton(systemImage: "square.and.pencil") {
            showCollectionBox = true
          }
          .accessibilityLabel("编辑收藏")
        }
      }
    }
    .subjectPreview(subject, eps: true)
    .sheet(isPresented: $showCollectionBox) {
      SubjectCollectionBoxView(subjectId: subject.id, onSaved: onCollectionSaved)
        .presentationDragIndicator(.visible)
    }
  }

  private var details: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 5) {
        if isPrivate {
          Image(systemName: "lock.fill")
            .font(.caption2)
            .foregroundStyle(theme.accent)
        }
        Text(titleText)
          .font(.subheadline.weight(.bold))
          .lineLimit(2)
      }
      if let info = subject.info, !info.isEmpty {
        Text(info)
          .font(.caption)
          .foregroundStyle(theme.tertiaryText)
          .lineLimit(1)
      }
      if let interest = subject.interest {
        interestLine(interest)
        if !interest.comment.isEmpty {
          ThemedDivider()
          Text(interest.comment)
            .font(.caption)
            .foregroundStyle(theme.secondaryText)
            .multilineTextAlignment(.leading)
            .textSelection(.enabled)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func interestLine(_ interest: SlimSubjectInterestDTO) -> some View {
    HStack(spacing: 6) {
      Text(interest.updatedAt.datetimeDisplay)
        .font(.caption.monospaced())
        .foregroundStyle(theme.placeholder)
        .lineLimit(1)
      Spacer(minLength: 0)
      if interest.rate > 0 {
        StarsView(score: Float(interest.rate), size: 12)
      }
    }
  }
}

struct GlassCollectionListView: View {
  let subjectType: SubjectType

  @State private var collectionType = CollectionType.collect
  @State private var reloader = false
  @State private var counts: [CollectionType: Int] = [:]

  @Environment(\.theme) private var theme

  func loadCounts() async {
    do {
      let db = try await AppContext.shared.getDB()
      let fetchedCounts = try await db.fetchCollectionCounts(subjectType: subjectType)
      withAnimation(.default) {
        counts = fetchedCounts
        if fetchedCounts[collectionType, default: 0] == 0,
          let preferredType = CollectionType.preferredAvailableType(in: fetchedCounts)
        {
          collectionType = preferredType
        }
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func load(limit: Int, offset: Int) async -> PagedDTO<SubjectDTO>? {
    do {
      let db = try await AppContext.shared.getDB()
      let fetched = try await db.fetchCollectionSubjects(
        subjectType: subjectType,
        collectionType: collectionType,
        limit: limit,
        offset: offset
      )
      return PagedDTO(data: fetched, total: counts[collectionType, default: 0])
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  func reloadAfterCollectionSaved() async {
    await loadCounts()
    withAnimation(.default) {
      reloader.toggle()
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      if counts.isEmpty {
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        GlassCollectionChips(
          subjectType: subjectType, counts: counts, selection: $collectionType
        )
        .padding(.vertical, 6)
        .onChange(of: collectionType) { _, _ in
          withAnimation(.default) {
            reloader.toggle()
          }
        }
        list
      }
    }
    .task {
      if counts.isEmpty {
        await loadCounts()
      }
    }
    .navigationTitle("我的\(subjectType.description)")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var list: some View {
    ScrollView(showsIndicators: false) {
      OffsetPagedView<SubjectDTO, _>(limit: 20, reloader: reloader, nextPageFunc: load) { item in
        GlassSubjectCollectionRow(
          subject: item.slim,
          isPrivate: item.interest?.private ?? false,
          showsCollectionEditButton: true,
          onCollectionSaved: { await reloadAfterCollectionSaved() }
        )
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.bottom, 26)
    }
  }
}
