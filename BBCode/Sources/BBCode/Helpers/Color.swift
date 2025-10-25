import SwiftUI

extension Color {
  init(hex: Int, opacity: Double = 1) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xff) / 255,
      green: Double((hex >> 08) & 0xff) / 255,
      blue: Double((hex >> 00) & 0xff) / 255,
      opacity: opacity
    )
  }

  init?(_ color: String) {
    var color = color.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    // check for web color alias
    if let alias = WebColorAlias.allCases.first(where: { String(describing: $0) == color }) {
      color = String(describing: alias.standardColor)
    }

    // check for standard web color name
    if let name = WebColor.allCases.first(where: { String(describing: $0) == color }) {
      self.init(hex: name.rawValue)
      return
    }

    // check for hex color
    if color.hasPrefix("#") {
      color = String(color.dropFirst())
    }

    // handle 3-digit hex color
    if color.count == 3, let hex = Int(color, radix: 16) {
      let r = (hex >> 8) & 0xf
      let g = (hex >> 4) & 0xf
      let b = hex & 0xf
      // convert to 6-digit by repeating each digit
      let fullHex = (r << 20) | (r << 16) | (g << 12) | (g << 8) | (b << 4) | b
      self.init(hex: fullHex)
      return
    }

    // handle 6-digit hex color
    if color.count == 6, let hex = Int(color, radix: 16) {
      self.init(hex: hex)
      return
    }

    // handle 8-digit hex color
    if color.count == 8, let hex = Int(color, radix: 16) {
      let a = (hex >> 24) & 0xff
      let r = (hex >> 16) & 0xff
      let g = (hex >> 8) & 0xff
      let b = hex & 0xff
      self.init(
        .sRGB,
        red: Double(r) / 255,
        green: Double(g) / 255,
        blue: Double(b) / 255,
        opacity: Double(a) / 255
      )
      return
    }

    return nil
  }
}

enum WebColorAlias: CaseIterable {
  case desert
  case lion
  case fallow
  case sand
  case aqua
  case fuchsia
  case maize
  case sunset

  var standardColor: WebColor {
    switch self {
    case .desert, .lion, .fallow: return .camel
    case .sand: return .ecru
    case .aqua: return .cyan
    case .fuchsia: return .magenta
    case .maize: return .corn
    case .sunset: return .champagne
    }
  }
}

enum WebColor: Int, CaseIterable {
  case almond = 0xefdecd
  case amaranth = 0xe52b50
  case amber = 0xffbf00
  case amethyst = 0x996699
  case apricot = 0xfbceb1
  case aquamarine = 0x7fffd4
  case arsenic = 0x3b444b
  case asparagus = 0x87a96b
  case auburn = 0xa52a2a
  case aureolin = 0xfdee00
  case azure = 0x007fff
  case beige = 0xf5f5dc
  case bisque = 0xffe4c4
  case bistre = 0x3d2b1f
  case black = 0x000000
  case blond = 0xfaf0be
  case blue = 0x0000ff
  case bone = 0xe3dac9
  case brass = 0xb5a642
  case bronze = 0xcd7f32
  case bubbles = 0xe7feff
  case burgundy = 0x800020
  case burlywood = 0xdeb887
  case byzantine = 0xbd33a4
  case byzantium = 0x702963
  case cadet = 0x536872
  case camel = 0xc19a6b
  case capri = 0x00bfff
  case cardinal = 0xc41e3a
  case carmine = 0x960018
  case carnelian = 0xb31b1b
  case ceil = 0x92a1cf
  case celadon = 0xace1af
  case cerulean = 0x007ba7
  case chamoisee = 0xa0785a
  case champagne = 0xfad6a5
  case charcoal = 0x36454f
  case chartreuse = 0xdfff00
  case chestnut = 0xcd5c5c
  case cinereous = 0x98817b
  case cinnabar = 0xe34234
  case cinnamon = 0xd2691e
  case citrine = 0xe4d00a
  case cobalt = 0x0047ab
  case coffee = 0x6f4e37
  case copper = 0xb87333
  case coral = 0xff7f50
  case cordovan = 0x893f45
  case corn = 0xfbec5d
  case cornsilk = 0xfff8dc
  case cream = 0xfffdd0
  case crimson = 0xdc143c
  case cyan = 0x00ffff
  case daffodil = 0xffff31
  case darkorange = 0xff8c00
  case dandelion = 0xf0e130
  case denim = 0x1560bd
  case dirt = 0x9b7653
  case ebony = 0x555d50
  case ecru = 0xc2b280
  case eggplant = 0x614051
  case emerald = 0x50c878
  case fawn = 0xe5aa70
  case feldgrau = 0x4d5d53
  case flame = 0xe25822
  case flax = 0xeedc82
  case folly = 0xff004f
  case fulvous = 0xe48400
  case gainsboro = 0xdcdcdc
  case gamboge = 0xe49b0f
  case ginger = 0xb06500
  case glaucous = 0x6082b6
  case glitter = 0xe6e8fa
  case gold = 0xffd700
  case grape = 0x6f2da8
  case gray = 0x808080
  case green = 0x00ff00
  case greenyellow = 0xadff2f
  case grullo = 0xa99a86
  case harlequin = 0x3fff00
  case heliotrope = 0xdf73ff
  case honeydew = 0xf0fff0
  case icterine = 0xfcf75e
  case indigo = 0x6f00ff
  case ivory = 0xfffff0
  case jade = 0x00a86b
  case jasmine = 0xf8de7e
  case jasper = 0xd73b3e
  case jet = 0x343434
  case jonquil = 0xfada5e
  case lava = 0xcf1020
  case lavender = 0xe6e6fa
  case lilac = 0xc8a2c8
  case lime = 0xbfff00
  case limerick = 0x9dc209
  case linen = 0xfaf0e6
  case liver = 0x534b4f
  case lust = 0xe62020
  case magenta = 0xff00ff
  case magnolia = 0xf8f4ff
  case mahogany = 0xc04000
  case malachite = 0x0bda51
  case manatee = 0x979aaa
  case mantis = 0x74c365
  case maroon = 0x800000
  case mauve = 0xe0b0ff
  case mauvelous = 0xef98aa
  case melon = 0xfdbcb4
  case mint = 0x3eb489
  case moccasin = 0xfaebd7
  case mulberry = 0xc54b8c
  case mustard = 0xffdb58
  case myrtle = 0x21421e
  case ochre = 0xcc7722
  case olive = 0x808000
  case olivine = 0x9ab973
  case onyx = 0x353839
  case orange = 0xffa500
  case orangered = 0xff4500
  case orchid = 0xda70d6
  case pear = 0xd1e231
  case pearl = 0xeae0c8
  case peridot = 0xe6e200
  case periwinkle = 0xccccff
  case phlox = 0xdf00ff
  case pink = 0xffc0cb
  case pistachio = 0x93c572
  case platinum = 0xe5e4e2
  case plum = 0x8e4585
  case puce = 0xcc8899
  case pumpkin = 0xff7518
  case purple = 0x800080
  case quartz = 0x51484f
  case rajah = 0xfbab60
  case raspberry = 0xe30b5d
  case red = 0xff0000
  case redwood = 0xab4e52
  case regalia = 0x522d80
  case rose = 0xff007f
  case rosewood = 0x65000b
  case ruby = 0xe0115f
  case ruddy = 0xff0028
  case rufous = 0xa81c07
  case russet = 0x80461b
  case rust = 0xb7410e
  case saffron = 0xf4c430
  case sage = 0xbcb88a
  case salmon = 0xff8c69
  case sandstorm = 0xecd540
  case sangria = 0x92000a
  case sapphire = 0x0f52ba
  case scarlet = 0xff2400
  case seashell = 0xfff5ee
  case sepia = 0x704214
  case shadow = 0x8a795d
  case sienna = 0x882d17
  case silver = 0xc0c0c0
  case sinopia = 0xcb410b
  case skobeloff = 0x007474
  case snow = 0xfffafa
  case straw = 0xe4d96f
  case tan = 0xd2b48c
  case tangelo = 0xf94d00
  case tangerine = 0xf28500
  case taupe = 0x483c32
  case teal = 0x008080
  case thistle = 0xd8bfd8
  case tomato = 0xff6347
  case topaz = 0xffc87c
  case tumbleweed = 0xdeaa88
  case turquoise = 0x30d5c8
  case ube = 0x8878c3
  case umber = 0x635147
  case vanilla = 0xf3e5ab
  case verdigris = 0x43b3ae
  case veronica = 0xa020f0
  case violet = 0x8f00ff
  case viridian = 0x40826d
  case waterspout = 0xa4f4f9
  case wenge = 0x645452
  case wheat = 0xf5deb3
  case white = 0xffffff
  case wine = 0x722f37
  case wisteria = 0xc9a0dc
  case xanadu = 0x738678
  case yellow = 0xffff00
  case yellowgreen = 0x9acd32
  case zaffre = 0x0014a8
}
