import SwiftUI

struct ChiiRakuenView: View {
  var body: some View {
    ScrollView {
      VStack {
        CardView {
          TrendingSubjectTopicsView()
        }
        CardView {
          RecentGroupTopicsView()
        }
      }.padding(.horizontal, 8)
    }
    .navigationTitle("超展开")
    .toolbarTitleDisplayMode(.inline)
  }
}
