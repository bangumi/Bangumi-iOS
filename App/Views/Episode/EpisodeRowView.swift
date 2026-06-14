import SwiftUI

struct EpisodeRowView: View {
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  let episode: EpisodeDTO
  var reload: (() async -> Void)? = nil

  var body: some View {
    VStack(alignment: .leading) {
      Text(episode.titleLink(with: titlePreference))
        .font(.headline)
        .lineLimit(1)
      HStack {
        if isAuthenticated && episode.collectionTypeEnum != .none {
          let colors = episode.badgeColors
          BorderView(color: colors.border, padding: 4) {
            Text("\(episode.collectionTypeEnum.description)")
              .foregroundStyle(colors.foreground)
              .font(.footnote)
          }
          .strikethrough(episode.status == EpisodeCollectionType.dropped.rawValue)
          .background {
            RoundedRectangle(cornerRadius: 5)
              .fill(colors.background)
          }
        } else {
          Menu {
            EpisodeUpdateMenu(episode: episode, reload: reload)
          } label: {
            if episode.typeEnum == .main {
              if episode.aired {
                BorderView(color: .primary, padding: 4) {
                  Text("已播")
                    .foregroundStyle(.primary)
                    .font(.footnote)
                }
              } else {
                BorderView(padding: 4) {
                  Text("未播")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                }
              }
            } else {
              BorderView(color: .primary, padding: 4) {
                Text(episode.typeEnum.description)
                  .foregroundStyle(.primary)
                  .font(.footnote)
              }
            }
          }.buttonStyle(.scale)
        }
        VStack(alignment: .leading) {
          HStack {
            Label("\(episode.duration)", systemImage: "clock")
            Label("\(episode.airdate)", systemImage: "calendar")
            Spacer()
            if isAuthenticated && episode.collectionTypeEnum != .none, episode.collectedAt > 0 {
              Text(
                "\(episode.collectionTypeEnum.description): \(episode.collectedAt.datetimeDisplay)"
              ).lineLimit(1)
            }
            if !isolationMode {
              Label("+\(episode.comment)", systemImage: "bubble")
            }
          }
          .font(.footnote)
          .foregroundStyle(.secondary)
          Divider()
        }
        Spacer()
      }
    }
  }
}
