import SwiftUI

struct BootstrapLoadingView: View {
  var body: some View {
    VStack {
      Spacer()
      Image(systemName: "waveform")
        .resizable()
        .scaledToFit()
        .frame(width: 72, height: 72)
        .symbolEffect(.variableColor.iterative.dimInactiveLayers)
      Spacer()
    }
    .padding(24)
  }
}

#Preview {
  BootstrapLoadingView()
}
