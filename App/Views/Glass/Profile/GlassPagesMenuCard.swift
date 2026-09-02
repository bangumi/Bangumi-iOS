import SwiftUI

struct GlassPageTile: Identifiable {
  let title: String
  let systemImage: String
  let destination: NavDestination
  let isPrimary: Bool

  var id: String {
    title
  }

  init(
    _ title: String, _ systemImage: String, _ destination: NavDestination,
    isPrimary: Bool = false
  ) {
    self.title = title
    self.systemImage = systemImage
    self.destination = destination
    self.isPrimary = isPrimary
  }
}

struct GlassPageTileButton: View {
  let tile: GlassPageTile

  @Environment(\.theme) private var theme

  init(tile: GlassPageTile) {
    self.tile = tile
  }

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
  }

  var body: some View {
    NavigationLink(value: tile.destination) {
      VStack(spacing: 5) {
        Image(systemName: tile.systemImage)
          .font(.body.weight(.semibold))
          .foregroundStyle(tile.isPrimary ? Color.white : theme.secondaryText)
          .frame(width: 42, height: 42)
          .background(iconFill, in: shape)
          .overlay {
            shape.strokeBorder(tile.isPrimary ? .clear : theme.controlBorder, lineWidth: 1)
          }
          .shadow(color: iconShadow.color, radius: iconShadow.radius, y: iconShadow.y)
        Text(tile.title)
          .font(.caption.weight(.semibold))
          .foregroundStyle(theme.sectionHeader)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private var iconFill: AnyShapeStyle {
    if tile.isPrimary {
      return AnyShapeStyle(
        LinearGradient(
          colors: theme.ctaGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
    }
    return AnyShapeStyle(theme.controlFill)
  }

  private var iconShadow: ThemeShadow {
    tile.isPrimary ? theme.ctaShadow : ThemeShadow(color: .clear, radius: 0, y: 0)
  }
}

struct GlassPagesMenuCard: View {
  let user: SlimUserDTO

  @State private var page: Int = 0
  @ScaledMetric(relativeTo: .caption) private var pageHeight: CGFloat = 76

  @Environment(\.theme) private var theme

  private let perPage = 5

  private var tiles: [GlassPageTile] {
    [
      GlassPageTile("时光机", "clock.arrow.circlepath", .user(user.username), isPrimary: true),
      GlassPageTile("人物", "theatermasks", .userMono(user)),
      GlassPageTile("日志", "book.closed", .userBlog(user)),
      GlassPageTile("目录", "list.bullet.rectangle", .userIndex(user)),
      GlassPageTile("时间胶囊", "hourglass", .userTimeline(user)),
      GlassPageTile("小组", "person.3", .userGroup(user)),
      GlassPageTile("好友", "person.2", .friends),
    ]
  }

  private var pageCount: Int {
    max(1, Int(ceil(Double(tiles.count) / Double(perPage))))
  }

  private func tiles(on index: Int) -> [GlassPageTile] {
    let start = index * perPage
    let end = min(start + perPage, tiles.count)
    guard start < end else { return [] }
    return Array(tiles[start..<end])
  }

  private func placeholders(on index: Int) -> Int {
    max(0, perPage - tiles(on: index).count)
  }

  var body: some View {
    CardView(padding: 13) {
      VStack(spacing: 6) {
        TabView(selection: $page) {
          ForEach(0..<pageCount, id: \.self) { index in
            HStack(spacing: 0) {
              ForEach(tiles(on: index)) { tile in
                GlassPageTileButton(tile: tile)
              }
              ForEach(0..<placeholders(on: index), id: \.self) { _ in
                Color.clear.frame(maxWidth: .infinity)
              }
            }
            .tag(index)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: pageHeight)
        if pageCount > 1 {
          dots
        }
      }
    }
  }

  private var dots: some View {
    HStack(spacing: 4) {
      ForEach(0..<pageCount, id: \.self) { index in
        Capsule()
          .fill(index == page ? theme.accentDeep : theme.track)
          .frame(width: index == page ? 14 : 4, height: 4)
      }
    }
    .animation(.easeInOut(duration: 0.18), value: page)
  }
}
