import SwiftUI

struct ThemeShadow: Equatable, Sendable {
  let color: Color
  let radius: CGFloat
  let y: CGFloat
}

struct ThemeMetrics: Equatable, Sendable {
  let cardRadius: CGFloat
  let embedRadius: CGFloat
  let controlRadius: CGFloat
  let coverRadius: CGFloat
  let badgeRadius: CGFloat
  let cellRadius: CGFloat
  let sheetRadius: CGFloat
  let cardPadding: CGFloat
  let listSpacing: CGFloat
  let screenPadding: CGFloat
}

struct ThemeGradientBlob: Equatable, Sendable, Identifiable {
  let id: Int
  let color: Color
  let center: UnitPoint
  let endRadius: CGFloat
}

enum EpisodeCellState: Sendable {
  case watched
  case next
  case aired
  case unaired
  case dropped
  case wish
}

struct EpisodeCellStyle: Equatable, Sendable {
  let fill: [Color]
  let border: Color
  let borderWidth: CGFloat
  let dashed: Bool
  let foreground: Color
  let strikethrough: Bool
}

struct ThemeTokens: Equatable, Sendable {
  let kind: AppTheme

  let pageGradient: [Color]
  let pageBlobs: [ThemeGradientBlob]
  let cardFill: Color
  let cardFillStrong: Color
  let cardFillOpaque: Color
  let cardBorder: Color
  let cardHighlight: Color
  let embedFill: Color
  let embedBorder: Color
  let controlFill: Color
  let controlFillOpaque: Color
  let controlBorder: Color
  let separator: Color
  let track: Color
  let imageBorder: Color
  let badgeRing: Color
  let maskFill: Color
  let toastFill: Color
  let toastText: Color

  let title: Color
  let cardTitle: Color
  let body: Color
  let sectionHeader: Color
  let secondaryText: Color
  let tertiaryText: Color
  let placeholder: Color
  let disabled: Color

  let accent: Color
  let accentDeep: Color
  let link: Color
  let onTintText: Color
  let tint: Color
  let star: Color
  let success: Color
  let successText: Color
  let danger: Color
  let warn: Color
  let warnFill: Color
  let rank: Color

  let ctaGradient: [Color]
  let avatarGradients: [[Color]]
  let selfGradient: [Color]

  let cardShadow: ThemeShadow
  let heroShadow: ThemeShadow
  let ctaShadow: ThemeShadow
  let chipShadow: ThemeShadow
  let metrics: ThemeMetrics

  var isClassic: Bool {
    kind == .classic
  }

  var bbcodePalette: BBCodePalette {
    switch kind {
    case .classic:
      .classic
    case .glass:
      .glass
    }
  }

  func collectionBadge(_ type: CollectionType) -> [Color] {
    if isClassic {
      return [type.color, type.color]
    }
    switch type {
    case .none:
      return [.clear, .clear]
    case .wish:
      return [
        .adaptive(light: 0xF7B267, dark: 0xF7B267), .adaptive(light: 0xF4845F, dark: 0xF4845F),
      ]
    case .collect:
      return [
        .adaptive(light: 0x5CC6A6, dark: 0x5CC6A6), .adaptive(light: 0x3A9E8C, dark: 0x3A9E8C),
      ]
    case .doing:
      return [
        .adaptive(light: 0xF2758B, dark: 0xF2758B), .adaptive(light: 0xE85F86, dark: 0xE85F86),
      ]
    case .onHold, .dropped:
      let neutral = Color.adaptive(
        light: 0xB48CA0, dark: 0xFFFFFF, lightOpacity: 0.18, darkOpacity: 0.12)
      return [neutral, neutral]
    }
  }

  func collectionBadgeText(_ type: CollectionType) -> Color {
    if isClassic {
      return .white
    }
    switch type {
    case .onHold, .dropped:
      return .adaptive(light: 0xB0A4AF, dark: 0x8F8494)
    default:
      return .white
    }
  }

  func subjectTint(_ type: SubjectType) -> (fill: Color, text: Color) {
    if isClassic {
      return (Color.accentColor.opacity(0.15), .accent)
    }
    switch type {
    case .none:
      return (
        .adaptive(light: 0xB48CA0, dark: 0xC8AABE, lightOpacity: 0.14, darkOpacity: 0.16),
        .adaptive(light: 0x6E6672, dark: 0xB7ACBA)
      )
    case .book:
      return (
        .adaptive(light: 0x5E9BD4, dark: 0x5E9BD4, lightOpacity: 0.14, darkOpacity: 0.224),
        .adaptive(light: 0x4A7CB5, dark: 0x9BC0E8)
      )
    case .anime:
      return (
        .adaptive(light: 0x7EC8E3, dark: 0x7EC8E3, lightOpacity: 0.16, darkOpacity: 0.256),
        .adaptive(light: 0x3E7FA8, dark: 0x96C9E5)
      )
    case .music:
      return (
        .adaptive(light: 0xA18CD1, dark: 0xA18CD1, lightOpacity: 0.16, darkOpacity: 0.256),
        .adaptive(light: 0x7B5FB5, dark: 0xC0A8E6)
      )
    case .game:
      return (
        .adaptive(light: 0x5CC6A6, dark: 0x5CC6A6, lightOpacity: 0.14, darkOpacity: 0.224),
        .adaptive(light: 0x2E8C74, dark: 0x8FDDC4)
      )
    case .real:
      return (
        .adaptive(light: 0xE0A2B8, dark: 0xE0A2B8, lightOpacity: 0.16, darkOpacity: 0.256),
        .adaptive(light: 0xC96F8F, dark: 0xEFA8BE)
      )
    }
  }

  func weekdayBanner(_ day: WeekDay) -> [Color] {
    if isClassic {
      return [day.color, day.color]
    }
    switch day {
    case .sun:
      return [
        .adaptive(light: 0xE0A2B8, dark: 0xE0A2B8), .adaptive(light: 0xC96F8F, dark: 0xC96F8F),
      ]
    case .mon:
      return [
        .adaptive(light: 0xF7B267, dark: 0xF7B267), .adaptive(light: 0xF4845F, dark: 0xF4845F),
      ]
    case .tue:
      return [
        .adaptive(light: 0x7EC8E3, dark: 0x7EC8E3), .adaptive(light: 0x5B8DEF, dark: 0x5B8DEF),
      ]
    case .wed:
      return [
        .adaptive(light: 0x5CC6A6, dark: 0x5CC6A6), .adaptive(light: 0x3A9E8C, dark: 0x3A9E8C),
      ]
    case .thu:
      return [
        .adaptive(light: 0xA18CD1, dark: 0xA18CD1), .adaptive(light: 0x8B5FBF, dark: 0x8B5FBF),
      ]
    case .fri:
      return [
        .adaptive(light: 0x9BB8F2, dark: 0x9BB8F2), .adaptive(light: 0x7E94E8, dark: 0x7E94E8),
      ]
    case .sat:
      return [
        .adaptive(light: 0xC8A2E0, dark: 0xC8A2E0), .adaptive(light: 0x9B6FC9, dark: 0x9B6FC9),
      ]
    }
  }

  func episodeCell(_ state: EpisodeCellState) -> EpisodeCellStyle {
    isClassic ? Self.classicEpisodeCell(state) : Self.glassEpisodeCell(state)
  }
}

extension ThemeTokens {
  init(_ kind: AppTheme) {
    switch kind {
    case .classic:
      self = .classic
    case .glass:
      self = .glass
    }
  }
}

extension ThemeTokens {
  static let classic = ThemeTokens(
    kind: .classic,
    pageGradient: [Color(uiColor: .systemBackground)],
    pageBlobs: [],
    cardFill: .cardBackground,
    cardFillStrong: .cardBackground,
    cardFillOpaque: .cardBackground,
    cardBorder: .clear,
    cardHighlight: .clear,
    embedFill: Color.secondary.opacity(0.01),
    embedBorder: Color.secondary.opacity(0.2),
    controlFill: Color(uiColor: .secondarySystemBackground),
    controlFillOpaque: Color(uiColor: .secondarySystemBackground),
    controlBorder: Color.secondary.opacity(0.2),
    separator: Color(uiColor: .separator),
    track: Color(uiColor: .systemFill),
    imageBorder: Color.primary.opacity(0.15),
    badgeRing: Color(uiColor: .systemBackground),
    maskFill: .black.opacity(0.55),
    toastFill: .accent,
    toastText: .white,
    title: .primary,
    cardTitle: .primary,
    body: .primary,
    sectionHeader: .primary,
    secondaryText: .secondary,
    tertiaryText: Color(uiColor: .tertiaryLabel),
    placeholder: Color(uiColor: .placeholderText),
    disabled: Color(uiColor: .quaternaryLabel),
    accent: .accent,
    accentDeep: .accent,
    link: .linkText,
    onTintText: .white,
    tint: Color.accentColor.opacity(0.15),
    star: .orange,
    success: .green,
    successText: .green,
    danger: .red,
    warn: .orange,
    warnFill: Color.orange.opacity(0.14),
    rank: .orange,
    ctaGradient: [.accent, .accent],
    avatarGradients: [[.accent, .accent]],
    selfGradient: [.accent, .accent],
    cardShadow: ThemeShadow(color: .black.opacity(0.2), radius: 2, y: 0),
    heroShadow: ThemeShadow(color: .black.opacity(0.2), radius: 2, y: 0),
    ctaShadow: ThemeShadow(color: .clear, radius: 0, y: 0),
    chipShadow: ThemeShadow(color: .clear, radius: 0, y: 0),
    metrics: ThemeMetrics(
      cardRadius: 8, embedRadius: 8, controlRadius: 8, coverRadius: 5, badgeRadius: 5,
      cellRadius: 2, sheetRadius: 0, cardPadding: 8, listSpacing: 8, screenPadding: 8)
  )

  static let glass = ThemeTokens(
    kind: .glass,
    pageGradient: [
      .adaptive(light: 0xFBF2F6, dark: 0x1E1922),
      .adaptive(light: 0xF5EFFA, dark: 0x171420),
    ],
    pageBlobs: [
      ThemeGradientBlob(
        id: 0,
        color: .adaptive(light: 0xFFDFEC, dark: 0x9E4860, darkOpacity: 0.42),
        center: UnitPoint(x: 0.12, y: 0.18), endRadius: 420),
      ThemeGradientBlob(
        id: 1,
        color: .adaptive(light: 0xE4D8FB, dark: 0x6B4C9E, darkOpacity: 0.40),
        center: UnitPoint(x: 0.92, y: 0.22), endRadius: 380),
      ThemeGradientBlob(
        id: 2,
        color: .adaptive(light: 0xFFE7D2, dark: 0x9E6638, darkOpacity: 0.28),
        center: UnitPoint(x: 0.82, y: 0.85), endRadius: 420),
      ThemeGradientBlob(
        id: 3,
        color: .adaptive(light: 0xD7E7FF, dark: 0x47669E, darkOpacity: 0.32),
        center: UnitPoint(x: 0.04, y: 0.85), endRadius: 360),
    ],
    cardFill: .adaptive(
      light: 0xFFFFFF, dark: 0xFFFFFF, lightOpacity: 0.62, darkOpacity: 0.07),
    cardFillStrong: .adaptive(
      light: 0xFFFFFF, dark: 0xFFFFFF, lightOpacity: 0.72, darkOpacity: 0.10),
    cardFillOpaque: .adaptive(light: 0xFFFFFF, dark: 0x2A2530),
    cardBorder: .adaptive(
      light: 0xFFFFFF, dark: 0xFFFFFF, lightOpacity: 0.60, darkOpacity: 0.12),
    cardHighlight: .adaptive(
      light: 0xFFFFFF, dark: 0xFFFFFF, lightOpacity: 0.75, darkOpacity: 0.10),
    embedFill: .adaptive(
      light: 0xFFFFFF, dark: 0xFFFFFF, lightOpacity: 0.50, darkOpacity: 0.05),
    embedBorder: .adaptive(
      light: 0xFFFFFF, dark: 0xFFFFFF, lightOpacity: 0.55, darkOpacity: 0.10),
    controlFill: .adaptive(
      light: 0xFFFFFF, dark: 0xFFFFFF, lightOpacity: 0.60, darkOpacity: 0.08),
    controlFillOpaque: .adaptive(light: 0xFFFFFF, dark: 0x332D39),
    controlBorder: .adaptive(
      light: 0xFFFFFF, dark: 0xFFFFFF, lightOpacity: 0.70, darkOpacity: 0.14),
    separator: .adaptive(
      light: 0xB48CA0, dark: 0xC8AABE, lightOpacity: 0.14, darkOpacity: 0.16),
    track: .adaptive(
      light: 0xB48CA0, dark: 0xFFFFFF, lightOpacity: 0.16, darkOpacity: 0.10),
    imageBorder: .adaptive(
      light: 0xFFFFFF, dark: 0xFFFFFF, lightOpacity: 0.70, darkOpacity: 0.12),
    badgeRing: .adaptive(
      light: 0xFFFFFF, dark: 0xFFFFFF, lightOpacity: 0.72, darkOpacity: 0.10),
    maskFill: .adaptive(
      light: 0x26232B, dark: 0x000000, lightOpacity: 0.55, darkOpacity: 0.60),
    toastFill: .adaptive(
      light: 0x26232B, dark: 0xF4EEF6, lightOpacity: 0.92, darkOpacity: 0.92),
    toastText: .adaptive(light: 0xFFFFFF, dark: 0x26232B),
    title: .adaptive(light: 0x26232B, dark: 0xF4EEF6),
    cardTitle: .adaptive(light: 0x33303A, dark: 0xEDE6F0),
    body: .adaptive(light: 0x3A353F, dark: 0xE4DCE7),
    sectionHeader: .adaptive(light: 0x4A444F, dark: 0xD3C9D6),
    secondaryText: .adaptive(light: 0x6E6672, dark: 0xB7ACBA),
    tertiaryText: .adaptive(light: 0xA99EA8, dark: 0x8F8494),
    placeholder: .adaptive(light: 0xB0A4AF, dark: 0x7E7383),
    disabled: .adaptive(light: 0xC9BCC6, dark: 0x5E5563),
    accent: .adaptive(light: 0xF2758B, dark: 0xF2758B),
    accentDeep: .adaptive(light: 0xE85F86, dark: 0xE85F86),
    link: .adaptive(light: 0xD14E6C, dark: 0xF08AA3),
    onTintText: .adaptive(light: 0xC4506B, dark: 0xF5A3B8),
    tint: .adaptive(
      light: 0xF2758B, dark: 0xF2758B, lightOpacity: 0.12, darkOpacity: 0.20),
    star: .adaptive(light: 0xF2A254, dark: 0xF2A254),
    success: .adaptive(light: 0x5CC6A6, dark: 0x5CC6A6),
    successText: .adaptive(light: 0x2E8C74, dark: 0x8FDDC4),
    danger: .adaptive(light: 0xE53935, dark: 0xFF6B67),
    warn: .adaptive(light: 0xA9682F, dark: 0xE0A46A),
    warnFill: .adaptive(
      light: 0xF2A254, dark: 0xF2A254, lightOpacity: 0.14, darkOpacity: 0.22),
    rank: .adaptive(light: 0xC07A35, dark: 0xE0A46A),
    ctaGradient: [
      .adaptive(light: 0xF2758B, dark: 0xF2758B),
      .adaptive(light: 0xE85F86, dark: 0xE85F86),
    ],
    avatarGradients: [
      [.adaptive(light: 0xF7B267, dark: 0xF7B267), .adaptive(light: 0xF4845F, dark: 0xF4845F)],
      [.adaptive(light: 0x7EC8E3, dark: 0x7EC8E3), .adaptive(light: 0x5B8DEF, dark: 0x5B8DEF)],
      [.adaptive(light: 0xA18CD1, dark: 0xA18CD1), .adaptive(light: 0x8B5FBF, dark: 0x8B5FBF)],
      [.adaptive(light: 0x5CC6A6, dark: 0x5CC6A6), .adaptive(light: 0x3A9E8C, dark: 0x3A9E8C)],
      [.adaptive(light: 0xE0A2B8, dark: 0xE0A2B8), .adaptive(light: 0xC96F8F, dark: 0xC96F8F)],
      [.adaptive(light: 0xC8A2E0, dark: 0xC8A2E0), .adaptive(light: 0x9B6FC9, dark: 0x9B6FC9)],
      [.adaptive(light: 0x9BD4A3, dark: 0x9BD4A3), .adaptive(light: 0x5FB876, dark: 0x5FB876)],
      [.adaptive(light: 0x9BB8F2, dark: 0x9BB8F2), .adaptive(light: 0x7E94E8, dark: 0x7E94E8)],
    ],
    selfGradient: [
      .adaptive(light: 0xF2758B, dark: 0xF2758B),
      .adaptive(light: 0xC86A9E, dark: 0xC86A9E),
    ],
    cardShadow: ThemeShadow(
      color: .adaptive(
        light: 0xB4788C, dark: 0x000000, lightOpacity: 0.12, darkOpacity: 0.35),
      radius: 10, y: 6),
    heroShadow: ThemeShadow(
      color: .adaptive(
        light: 0xB4788C, dark: 0x000000, lightOpacity: 0.13, darkOpacity: 0.40),
      radius: 14, y: 8),
    ctaShadow: ThemeShadow(
      color: .adaptive(
        light: 0xE85F86, dark: 0xE85F86, lightOpacity: 0.35, darkOpacity: 0.35),
      radius: 8, y: 4),
    chipShadow: ThemeShadow(
      color: .adaptive(
        light: 0xE85F86, dark: 0xE85F86, lightOpacity: 0.30, darkOpacity: 0.30),
      radius: 6, y: 3),
    metrics: ThemeMetrics(
      cardRadius: 22, embedRadius: 16, controlRadius: 14, coverRadius: 12, badgeRadius: 9,
      cellRadius: 10, sheetRadius: 32, cardPadding: 16, listSpacing: 12, screenPadding: 16)
  )
}

extension ThemeTokens {
  fileprivate static func classicEpisodeCell(_ state: EpisodeCellState) -> EpisodeCellStyle {
    switch state {
    case .watched:
      EpisodeCellStyle(
        fill: [Color(hex: 0x4897FF)], border: Color(hex: 0x1175A8), borderWidth: 1,
        dashed: false, foreground: Color(hex: 0xFFFFFF), strikethrough: false)
    case .next, .aired:
      EpisodeCellStyle(
        fill: [Color(hex: 0xDAEAFF)], border: Color(hex: 0x00A8FF), borderWidth: 1,
        dashed: false, foreground: Color(hex: 0x0066CC), strikethrough: false)
    case .unaired:
      EpisodeCellStyle(
        fill: [Color(hex: 0xE0E0E0)], border: Color(hex: 0x909090), borderWidth: 1,
        dashed: false, foreground: Color(hex: 0x909090), strikethrough: false)
    case .dropped:
      EpisodeCellStyle(
        fill: [Color(hex: 0xCCCCCC)], border: Color(hex: 0x666666), borderWidth: 1,
        dashed: false, foreground: Color(hex: 0xFFFFFF), strikethrough: true)
    case .wish:
      EpisodeCellStyle(
        fill: [Color(hex: 0xFFADD1)], border: Color(hex: 0xFF2293), borderWidth: 1,
        dashed: false, foreground: Color(hex: 0xFF2293), strikethrough: false)
    }
  }

  fileprivate static func glassEpisodeCell(_ state: EpisodeCellState) -> EpisodeCellStyle {
    switch state {
    case .watched:
      EpisodeCellStyle(
        fill: ThemeTokens.glass.ctaGradient, border: .clear, borderWidth: 0,
        dashed: false, foreground: .adaptive(light: 0xFFFFFF, dark: 0xFFFFFF),
        strikethrough: false)
    case .next:
      EpisodeCellStyle(
        fill: [
          .adaptive(light: 0xFFFFFF, dark: 0xFFFFFF, lightOpacity: 0.80, darkOpacity: 0.10)
        ],
        border: .adaptive(light: 0xF2758B, dark: 0xF2758B), borderWidth: 1.5,
        dashed: false, foreground: .adaptive(light: 0xE85F86, dark: 0xF08AA3),
        strikethrough: false)
    case .aired:
      EpisodeCellStyle(
        fill: [
          .adaptive(light: 0xFFFFFF, dark: 0xFFFFFF, lightOpacity: 0.65, darkOpacity: 0.08)
        ],
        border: .adaptive(
          light: 0xFFFFFF, dark: 0xFFFFFF, lightOpacity: 0.90, darkOpacity: 0.12),
        borderWidth: 1,
        dashed: false, foreground: .adaptive(light: 0x6E6672, dark: 0xB7ACBA),
        strikethrough: false)
    case .unaired:
      EpisodeCellStyle(
        fill: [.clear],
        border: .adaptive(
          light: 0xB48CA0, dark: 0xC8AABE, lightOpacity: 0.45, darkOpacity: 0.45),
        borderWidth: 1.5,
        dashed: true, foreground: .adaptive(light: 0xC9BCC6, dark: 0x5E5563),
        strikethrough: false)
    case .dropped:
      EpisodeCellStyle(
        fill: [
          .adaptive(light: 0xB48CA0, dark: 0xFFFFFF, lightOpacity: 0.18, darkOpacity: 0.12)
        ],
        border: .clear, borderWidth: 0,
        dashed: false, foreground: .adaptive(light: 0xB0A4AF, dark: 0x7E7383),
        strikethrough: true)
    case .wish:
      EpisodeCellStyle(
        fill: [
          .adaptive(light: 0x5E9BD4, dark: 0x5E9BD4, lightOpacity: 0.14, darkOpacity: 0.22)
        ],
        border: .adaptive(
          light: 0x5E9BD4, dark: 0x5E9BD4, lightOpacity: 0.35, darkOpacity: 0.45),
        borderWidth: 1,
        dashed: false, foreground: .adaptive(light: 0x4A7CB5, dark: 0x9BC0E8),
        strikethrough: false)
    }
  }
}

struct ThemeKey: EnvironmentKey {
  static let defaultValue = ThemeTokens.classic
}

extension EnvironmentValues {
  var theme: ThemeTokens {
    get { self[ThemeKey.self] }
    set { self[ThemeKey.self] = newValue }
  }
}

extension Color {
  static func adaptive(
    light: Int, dark: Int, lightOpacity: CGFloat = 1, darkOpacity: CGFloat = 1
  ) -> Color {
    Color(
      uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
          ? UIColor(hex: dark, alpha: darkOpacity)
          : UIColor(hex: light, alpha: lightOpacity)
      })
  }
}

extension UIColor {
  convenience init(hex: Int, alpha: CGFloat) {
    self.init(
      red: CGFloat((hex >> 16) & 0xff) / 255,
      green: CGFloat((hex >> 08) & 0xff) / 255,
      blue: CGFloat((hex >> 00) & 0xff) / 255,
      alpha: alpha
    )
  }
}
