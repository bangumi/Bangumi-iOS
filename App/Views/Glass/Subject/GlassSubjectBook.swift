import Foundation
import OSLog
import SwiftUI

struct GlassSubjectBookProgress: View {
  let subject: SubjectDTO
  let reload: () async -> Void

  @Environment(\.theme) private var theme

  @State private var inputEps: String = ""
  @State private var eps: Int? = nil
  @State private var inputVols: String = ""
  @State private var vols: Int? = nil
  @State private var updating: Bool = false

  private var updateButtonDisable: Bool {
    if updating {
      return true
    }
    return eps == nil && vols == nil
  }

  private var epStatus: Int {
    subject.interest?.epStatus ?? 0
  }

  private var volStatus: Int {
    subject.interest?.volStatus ?? 0
  }

  private func parseInputEps() {
    if let newEps = Int(inputEps) {
      self.eps = newEps
    } else {
      self.eps = nil
    }
  }

  private func parseInputVols() {
    if let newVols = Int(inputVols) {
      self.vols = newVols
    } else {
      self.vols = nil
    }
  }

  private func incrEps() {
    if let value = eps {
      self.inputEps = "\(value+1)"
    } else {
      self.inputEps = "\(epStatus+1)"
    }
    parseInputEps()
  }

  private func incrVols() {
    if let value = vols {
      self.inputVols = "\(value+1)"
    } else {
      self.inputVols = "\(volStatus+1)"
    }
    parseInputVols()
  }

  private func reset() {
    self.eps = nil
    self.vols = nil
    self.inputEps = ""
    self.inputVols = ""
  }

  private func update() {
    self.updating = true

    Task {
      do {
        try await SubjectRepository.updateSubjectProgress(
          subjectId: subject.id, eps: eps, vols: vols)
        await reload()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } catch {
        Notifier.shared.alert(error: error)
      }
      self.reset()
      self.updating = false
    }
  }

  var body: some View {
    VStack(spacing: 9) {
      HStack(spacing: 8) {
        stepper(
          title: "Chap.", accessibilityLabel: "话数加一", value: $inputEps,
          status: epStatus, total: subject.epsDesc, action: incrEps)
        stepper(
          title: "Vol.", accessibilityLabel: "卷数加一", value: $inputVols,
          status: volStatus, total: subject.volumesDesc, action: incrVols)
      }
      Button(action: update) {
        Text("更新进度")
          .opacity(updating ? 0 : 1)
          .overlay {
            if updating {
              ProgressView()
            }
          }
      }
      .buttonStyle(.themedProminent)
      .disabled(updateButtonDisable)
    }
    .disabled(updating)
    .onChange(of: inputEps) { _, _ in parseInputEps() }
    .onChange(of: inputVols) { _, _ in parseInputVols() }
  }

  private func stepper(
    title: String,
    accessibilityLabel: LocalizedStringKey,
    value: Binding<String>,
    status: Int,
    total: String,
    action: @escaping () -> Void
  ) -> some View {
    HStack(spacing: 8) {
      Text(verbatim: title)
        .font(.caption2.weight(.semibold))
        .monospaced()
        .foregroundStyle(theme.placeholder)
      TextField("\(status)", text: value)
        .keyboardType(.numberPad)
        .textFieldStyle(.plain)
        .font(.headline.weight(.heavy))
        .monospaced()
        .foregroundStyle(theme.cardTitle)
        .frame(maxWidth: .infinity, alignment: .leading)
      if total != "??" {
        Text(verbatim: "/\(total)")
          .font(.caption2)
          .monospaced()
          .foregroundStyle(theme.tertiaryText)
      }
      Button(action: action) {
        Image(systemName: "plus")
          .font(.caption.weight(.heavy))
          .foregroundStyle(theme.onTintText)
          .frame(width: 28, height: 28)
          .background(
            theme.tint,
            in: RoundedRectangle(cornerRadius: theme.metrics.badgeRadius, style: .continuous)
          )
      }
      .buttonStyle(.plain)
      .accessibilityLabel(accessibilityLabel)
    }
    .lineLimit(1)
    .padding(.horizontal, 12)
    .padding(.vertical, 9)
    .background(
      theme.controlFill,
      in: RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
    )
    .overlay {
      RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
        .strokeBorder(theme.controlBorder, lineWidth: 1)
    }
  }
}

struct GlassSubjectOffprints: View {
  let subjectId: Int
  let offprints: [SubjectRelationDTO]

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Environment(\.theme) private var theme
  @State private var collections: [Int: CollectionType] = [:]
  @State private var activeSubject: SlimSubjectDTO? = nil

  private var collectionSubjectIds: [Int] {
    offprints.map { $0.subject.id }
  }

  private func loadCollections() async {
    do {
      let db = try await AppContext.shared.getDB()
      collections = try await db.getCollectionTypes(subjectIds: collectionSubjectIds)
    } catch {
      Logger.app.error("Failed to load collections: \(error)")
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ThemedSectionHeader("单行本") {
        if !offprints.isEmpty {
          Text("共 \(offprints.count) 卷")
            .font(.caption2.weight(.semibold))
            .monospaced()
            .foregroundStyle(theme.tertiaryText)
        }
      }
      if offprints.isEmpty {
        GlassSubjectEmptyRow(text: "暂无单行本")
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack(alignment: .top, spacing: 8) {
            ForEach(offprints) { offprint in
              VStack(alignment: .leading, spacing: 5) {
                ImageView(img: offprint.subject.images?.resize(.r200))
                  .imageCollectionStatus(ctype: collections[offprint.subject.id])
                  .imageStyle(
                    width: 66, height: 94, cornerRadius: theme.metrics.coverRadius)
                  .imageType(.subject)
                  .imageNSFW(offprint.subject.nsfw)
                  .imageNavLink(offprint.subject.link)
                  .contextMenu {
                    Button {
                      activeSubject = offprint.subject
                    } label: {
                      Label("管理收藏", systemImage: "square.and.pencil")
                    }
                  } preview: {
                    SubjectCardView(subject: offprint.subject)
                      .padding()
                      .frame(idealWidth: 360)
                  }
                  .shadow(
                    color: theme.cardShadow.color, radius: theme.cardShadow.radius,
                    y: theme.cardShadow.y)
                Text(offprint.subject.title(with: titlePreference))
                  .font(.caption2)
                  .foregroundStyle(theme.secondaryText)
                  .multilineTextAlignment(.leading)
                  .truncationMode(.middle)
                  .lineLimit(2, reservesSpace: true)
              }
              .frame(width: 66, alignment: .leading)
            }
          }
          .padding(.horizontal, 2)
          .padding(.vertical, 2)
        }
        .scrollClipDisabled()
      }
    }
    .task(id: collectionSubjectIds) {
      await loadCollections()
    }
    .onChange(of: activeSubject) { _, newValue in
      if newValue == nil {
        Task {
          await loadCollections()
        }
      }
    }
    .sheet(item: $activeSubject) { item in
      SubjectCollectionBoxView(subjectId: item.id)
    }
  }
}

struct GlassSubjectDiscs: View {
  let subjectId: Int

  @Environment(\.theme) private var theme
  @State private var refreshed: Bool = false
  @State private var episodes: [EpisodeDTO] = []

  private var discs: [Int: [EpisodeDTO]] {
    var discs: [Int: [EpisodeDTO]] = [:]
    for episode in episodes {
      discs[episode.disc, default: []].append(episode)
    }
    return discs
  }

  private func loadCached() async {
    do {
      let db = try await AppContext.shared.getDB()
      let fetchedEpisodes = try await db.fetchDiscEpisodes(subjectId: subjectId)
      withAnimation(.default) {
        episodes = fetchedEpisodes
      }
    } catch {
      Logger.app.error("Failed to load cached disc episodes: \(error)")
    }
  }

  private func refresh() {
    if refreshed { return }
    refreshed = true

    Task {
      do {
        try await EpisodeRepository.loadEpisodes(subjectId)
        await loadCached()
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ThemedSectionHeader("曲目列表")
      if episodes.isEmpty {
        GlassSubjectEmptyRow(text: "暂无曲目")
      } else {
        CardView(padding: theme.metrics.cardPadding) {
          VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(discs.keys.sorted()), id: \.self) { disc in
              Text("DISC \(disc)")
                .font(.caption2.weight(.bold))
                .monospaced()
                .foregroundStyle(theme.placeholder)
                .padding(.top, 7)
                .padding(.bottom, 3)
              ForEach(discs[disc] ?? []) { episode in
                trackRow(episode)
                if episode.id != discs[disc]?.last?.id {
                  ThemedDivider()
                }
              }
            }
          }
        }
      }
    }
    .task {
      await loadCached()
      refresh()
    }
  }

  private func trackRow(_ episode: EpisodeDTO) -> some View {
    NavigationLink(value: NavDestination.episode(episode.id)) {
      HStack(alignment: .firstTextBaseline, spacing: 9) {
        Text(episode.sort.episodeDisplay)
          .font(.caption.weight(.bold))
          .monospaced()
          .foregroundStyle(theme.tertiaryText)
          .frame(width: 26, alignment: .trailing)
        VStack(alignment: .leading, spacing: 2) {
          Text(episode.name)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(theme.cardTitle)
            .multilineTextAlignment(.leading)
            .lineLimit(1)
          if !episode.nameCN.isEmpty {
            Text(episode.nameCN)
              .font(.caption2)
              .foregroundStyle(theme.tertiaryText)
              .multilineTextAlignment(.leading)
              .lineLimit(1)
          }
        }
        Spacer(minLength: 0)
        if !episode.duration.isEmpty {
          Text(episode.duration)
            .font(.caption2.weight(.semibold))
            .monospaced()
            .foregroundStyle(theme.placeholder)
        }
      }
      .padding(.vertical, 8)
    }
    .buttonStyle(.plain)
  }
}
