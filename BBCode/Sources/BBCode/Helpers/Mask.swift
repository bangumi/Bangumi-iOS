import SwiftUI

enum MaskTextColor: Int {
  case show = 0xFFFFFF
  case hide = 0x555555

  var color: Color {
    Color(hex: rawValue)
  }
}

struct MaskView<Content: View>: View {
  let inner: () -> Content

  @State private var color: MaskTextColor = MaskTextColor.hide

  init(@ViewBuilder inner: @escaping () -> Content) {
    self.inner = inner
  }

  var body: some View {
    inner()
      .padding(2)
      .background(MaskTextColor.hide.color)
      .foregroundColor(color.color)
      .cornerRadius(2)
      .shadow(color: MaskTextColor.hide.color, radius: 2)
      .animation(.default, value: color)
      .onHover { hovered in
        if hovered {
          color = MaskTextColor.show
        } else {
          color = MaskTextColor.hide
        }
      }
      .onTapGesture {
        if color == MaskTextColor.hide {
          color = MaskTextColor.show
        } else {
          color = MaskTextColor.hide
        }
      }
  }
}
