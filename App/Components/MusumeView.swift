import SwiftUI

struct MusumeView: View {
  let index: Int?
  let width: CGFloat?
  let height: CGFloat?

  private let originalWidth: CGFloat = 40
  private let originalHeight: CGFloat = 75

  @State private var musumeIndex: Int = 0

  init(
    index: Int? = nil,
    width: CGFloat? = nil,
    height: CGFloat? = nil
  ) {
    self.index = index
    self.width = width
    self.height = height
  }

  private var displayWidth: CGFloat {
    width ?? originalWidth  // Default width is original size (scale 1)
  }

  private var scale: CGFloat {
    displayWidth / originalWidth
  }

  private var clippedWidth: CGFloat {
    displayWidth - 1
  }

  private var displayHeight: CGFloat {
    height ?? originalHeight * scale  // Default height scales with width, or use provided height for clipping
  }

  private var displayIndex: Int {
    if let index = index {
      return index % 7
    }
    return musumeIndex
  }

  private var offsetX: CGFloat {
    -originalWidth * scale * CGFloat(displayIndex)
  }

  var body: some View {
    Image("Musume")
      .scaleEffect(x: scale, y: scale, anchor: .bottomLeading)
      .offset(x: offsetX, y: 10 * scale)
      .frame(width: clippedWidth, height: displayHeight, alignment: .bottomLeading)
      .clipped()
      .onAppear {
        if index == nil {
          musumeIndex = Int.random(in: 0...6)
        }
      }
  }
}

#Preview {
  ScrollView {
    VStack(spacing: 20) {
      MusumeView()
      Divider()
      MusumeView(index: 0)
      MusumeView(index: 1)
      MusumeView(index: 2)
      MusumeView(index: 3)
      MusumeView(index: 4)
      MusumeView(index: 5)
      MusumeView(index: 6)
      Divider()
      MusumeView(index: 2, width: 40)
      MusumeView(index: 4, width: 80, height: 100)
      MusumeView(width: 30, height: 50)
    }
    .padding()
  }
}
