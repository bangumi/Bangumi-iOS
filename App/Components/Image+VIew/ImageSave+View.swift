import SDWebImageSwiftUI
import SwiftUI

extension View {
  @ViewBuilder
  func enableSave(_ large: String?) -> some View {
    if let large = large, let imageURL = URL(string: large) {
      self.contextMenu {
        Button {
          Task {
            guard let data = try? await URLSession.shared.data(from: imageURL).0 else { return }
            guard let img = UIImage(data: data) else { return }
            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
          }
        } label: {
          Label("保存", systemImage: "square.and.arrow.down")
        }
        ShareLink(item: imageURL)
      } preview: {
        AnimatedImage(url: imageURL)
          .resizable()
          .transition(.fade(duration: 0.25))
          .scaledToFit()
      }
    } else {
      self
    }
  }
}
