import Flow
import SwiftUI

struct GlassBlogView: View {
  let blog: BlogEntryDTO
  let subjects: [SlimSubjectDTO]

  @AppStorage("isolationMode") var isolationMode: Bool = false

  @Environment(\.theme) private var theme

  private var stats: String {
    "\(blog.views) 次浏览"
  }

  private var headerCard: some View {
    CardView(padding: theme.metrics.cardPadding, role: .strong) {
      VStack(alignment: .leading, spacing: 11) {
        Text(blog.title)
          .font(.title3.weight(.bold))
          .foregroundStyle(theme.title)
          .textSelection(.enabled)
        HStack(alignment: .center, spacing: 10) {
          ImageView(img: blog.user.avatar?.large)
            .imageStyle(width: 38, height: 38)
            .imageType(.avatar)
            .imageLink(blog.user.link)
          VStack(alignment: .leading, spacing: 3) {
            Text(blog.user.nickname.withLink(blog.user.link, linkColor: theme.link))
              .font(.footnote.weight(.bold))
              .lineLimit(1)
            GlassMonoCaption(text: blog.createdAt.datetimeDisplay)
          }
          Spacer(minLength: 0)
          if !blog.public {
            GlassMonoTag(text: "仅自己可见")
          }
        }
        if !blog.tags.isEmpty {
          HFlow(spacing: 5) {
            ForEach(blog.tags, id: \.self) { tag in
              GlassMonoTag(text: tag, tone: .accent)
            }
          }
        }
        ThemedDivider()
        HStack(spacing: 8) {
          GlassMonoCaption(text: stats)
          Spacer(minLength: 0)
          if !isolationMode {
            CommentListNavigationLink(
              route: CommentListRoute(parent: .blog(blog.id)),
              count: blog.replies
            )
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: theme.metrics.listSpacing) {
        headerCard
        CardView(padding: theme.metrics.cardPadding) {
          BBCodeView(blog.content)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        if !subjects.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            ThemedSectionHeader("关联条目", systemImage: "square.stack")
            VStack(spacing: theme.metrics.listSpacing) {
              ForEach(subjects) { subject in
                GlassSubjectEmbed(subject: subject)
              }
            }
          }
        }
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.vertical, 12)
    }
  }
}
