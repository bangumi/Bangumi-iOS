import SwiftUI

struct SubjectReviewsView: View {
  let subjectId: Int
  let reviews: [SubjectReviewDTO]

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("评论")
          .foregroundStyle(reviews.count > 0 ? .primary : .secondary)
          .font(.title3)
        Spacer()
        if reviews.count > 0 {
          NavigationLink(value: NavDestination.subjectReviewList(subjectId)) {
            Text("更多评论 »").font(.caption)
          }.buttonStyle(.navLink)
        }
      }
      Divider()
    }.padding(.top, 5)
    if reviews.count == 0 {
      HStack {
        Spacer()
        Text("暂无评论")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
      }.padding(.bottom, 5)
    }
    VStack {
      ForEach(reviews) { review in
        if !hideBlocklist || !blocklist.contains(review.user.id) {
          VStack {
            SubjectReviewItemView(item: review)
            Divider()
          }.padding(.top, 2)
        }
      }
    }
    .animation(.default, value: reviews)
  }
}

#Preview {
  NavigationStack {
    ScrollView {
      LazyVStack(alignment: .leading) {
        SubjectReviewsView(
          subjectId: Subject.previewAnime.subjectId,
          reviews: Subject.previewReviews
        )
      }.padding()
    }.modelContainer(mockContainer())
  }
}
