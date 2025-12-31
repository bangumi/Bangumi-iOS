import SwiftData
import SwiftUI

struct UserSubjectCollectionRowView: View {
  let subject: SlimSubjectDTO

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  var body: some View {
    HStack(alignment: .top) {
      ImageView(img: subject.images?.resize(.r200))
        .imageStyle(width: 60, height: subject.type.coverHeight(for: 60))
        .imageType(.subject)
        .imageLink(subject.link)
      VStack(alignment: .leading) {
        Text(subject.title(with: titlePreference).withLink(subject.link))
          .lineLimit(1)
        if let subtitle = subject.subtitle(with: titlePreference) {
          Text(subtitle)
            .lineLimit(1)
            .font(.caption)
            .foregroundStyle(.secondary.opacity(0.8))
        }
        Text(subject.info ?? "")
          .lineLimit(1)
          .font(.footnote)
          .foregroundStyle(.secondary)
        Spacer()
        if let interest = subject.interest {
          HStack {
            Text(interest.updatedAt.datetimeDisplay)
              .foregroundStyle(.secondary)
              .lineLimit(1)
            Spacer()
            if interest.rate > 0 {
              StarsView(score: Float(interest.rate), size: 12)
            }
          }.font(.footnote)
          if !interest.comment.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
              Divider()
              Text(interest.comment)
                .padding(2)
                .font(.footnote)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
            }
          }
        }
      }
    }
    .buttonStyle(.navigation)
    .frame(minHeight: 60)
    .padding(2)
    .clipShape(RoundedRectangle(cornerRadius: 10))
  }
}
