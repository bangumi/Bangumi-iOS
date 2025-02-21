import SwiftUI

struct RakuenTopicsView: View {
  @State private var selectedTab = 0

  var body: some View {
    VStack {
      Picker("Topics", selection: $selectedTab) {
        Text("小组话题").tag(0)
        Text("条目讨论").tag(1)
      }
      .pickerStyle(.segmented)
      .padding(.horizontal, 8)

      TabView(selection: $selectedTab) {
        RakuenGroupTopicView()
          .tag(0)

        RakuenSubjectTopicView()
          .tag(1)
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      .animation(.default, value: selectedTab)
    }
  }
}
