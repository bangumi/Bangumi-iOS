import SwiftUI

struct NotFoundView: View {
  var body: some View {
    VStack {
      Spacer()
      Image("404")
        .resizable()
        .scaledToFit()
        .frame(width: 160, height: 160)
      Text("呜咕，出错了").font(.headline).foregroundStyle(.accent)
      Text("啊噢，你访问的页面似乎被 Bangumi 娘吃掉了。").font(.footnote).foregroundStyle(.secondary)
      Spacer()
    }
  }
}

#Preview {
  NotFoundView()
}
