import SwiftUI

struct ChiiDiscoverView: View {
  var body: some View {
    ScrollView {
      VStack {
        CalendarSlimView()
        TrendingSubjectView()
      }.padding(.horizontal, 8)
    }
  }
}
