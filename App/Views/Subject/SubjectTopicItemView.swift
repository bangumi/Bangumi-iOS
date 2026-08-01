import SwiftUI

struct SubjectTopicItemView: View {
  let topic: TopicDTO

  var body: some View {
    CardView {
      VStack(alignment: .leading) {
        NavigationLink(value: NavDestination.subjectTopicDetail(topic.id)) {
          TopicTitleView(
            title: topic.title,
            createdAt: topic.createdAt,
            replyCount: topic.replyCount
          )
            .font(.callout)
            .multilineTextAlignment(.leading)
        }
        HStack {
          HStack(spacing: 0) {
            Text(topic.createdAt.dateDisplay)
              .lineLimit(1)
            if topic.replyCount ?? 0 > 0 {
              Text(" · ")
              Text("\(topic.replyCount ?? 0) replies")
                .lineLimit(1)
            }
          }.foregroundStyle(.secondary)
          Spacer()
          if let creator = topic.creator {
            Text(creator.nickname.withLink(creator.link))
              .lineLimit(1)
          }
        }.font(.footnote)
      }
    }
    .blocklistFilter(topic.creator?.id ?? 0, placeholder: false)
  }
}
