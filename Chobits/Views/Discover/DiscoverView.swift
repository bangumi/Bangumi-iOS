import SwiftUI

struct ChiiDiscoverView: View {
  var body: some View {
    ScrollView {
      LazyVStack {
        CalendarSlimView()
        TrendingSubjectView()
      }.padding(.horizontal, 8)
    }
  }
}
