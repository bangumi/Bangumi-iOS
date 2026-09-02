import SwiftUI

struct EpisodeInfoView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  let episode: EpisodeDTO

  func field(name: String, value: String) -> AttributedString {
    var text = AttributedString(name + ": ")
    var value = AttributedString(value)
    value.foregroundColor = .secondary
    text.append(value)
    return text
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      HStack(alignment: .bottom) {
        Text(episode.title(with: titlePreference))
          .font(.title3)
          .lineLimit(1)
        BorderView {
          Text(episode.typeEnum.description)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize()
        }
        Spacer()
      }
      ThemedDivider()
      if !episode.name.isEmpty {
        Text(field(name: "标题", value: episode.name))
      }
      if !episode.nameCN.isEmpty {
        Text(field(name: "中文标题", value: episode.nameCN))
      }
      if !episode.airdate.isEmpty {
        Text(field(name: "首播时间", value: episode.airdate))
      }
      if !episode.duration.isEmpty {
        Text(field(name: "时长", value: episode.duration))
      }
      if episode.disc > 0 {
        Text(field(name: "Disc", value: "\(episode.disc)"))
      }
      if isAuthenticated && episode.collectionTypeEnum != .none && episode.collectedAt > 0 {
        ThemedDivider()
        HStack {
          Spacer()
          Text(
            "\(episode.collectionTypeEnum.description): \(episode.collectedAt.datetimeDisplay)"
          )
          .font(.footnote)
          .foregroundStyle(.secondary)
          .lineLimit(1)
        }
      }
    }
  }
}
