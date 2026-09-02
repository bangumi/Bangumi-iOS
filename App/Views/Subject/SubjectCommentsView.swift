import SwiftUI

struct SubjectCommentsView: View {
  let subjectId: Int
  let subjectType: SubjectType
  let comments: [SubjectCommentDTO]

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()

  @Environment(\.theme) private var theme

  var body: some View {
    if theme.isClassic {
      VStack(spacing: 2) {
        HStack(alignment: .bottom) {
          Text("吐槽箱")
            .foregroundStyle(comments.count > 0 ? .primary : .secondary)
            .font(.title3)
          Spacer()
          if comments.count > 0 {
            NavigationLink(value: NavDestination.subjectCommentList(subjectId)) {
              Text("更多吐槽 »").font(.caption)
            }.buttonStyle(.navigation)
          }
        }
        Divider()
      }.padding(.top, 5)
    } else {
      ThemedSectionHeader {
        Text("吐槽箱")
          .foregroundStyle(comments.count > 0 ? theme.sectionHeader : theme.tertiaryText)
      } trailing: {
        if comments.count > 0 {
          NavigationLink(value: NavDestination.subjectCommentList(subjectId)) {
            Text("更多吐槽 »").font(.caption)
          }.buttonStyle(.navigation)
        }
      }
    }
    if comments.count == 0 {
      HStack {
        Spacer()
        Text("暂无吐槽")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
      }.padding(.bottom, 5)
    }
    LazyVStack {
      ForEach(comments) { comment in
        SubjectCommentItemView(subjectType: subjectType, comment: comment)
      }
    }
  }
}
