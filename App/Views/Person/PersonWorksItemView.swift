import Flow
import SwiftUI

struct PersonWorksItemView: View {
  let item: PersonWorkDTO

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  var body: some View {
    CardView {
      HStack(alignment: .top) {
        ImageView(img: item.subject.images?.resize(.r200))
          .imageStyle(width: 60, height: 60)
          .imageType(.subject)
          .imageNavLink(item.subject.link)
        VStack(alignment: .leading) {
          VStack(alignment: .leading) {
            Text(item.subject.title(with: titlePreference).withLink(item.subject.link))
              .font(.callout)
              .lineLimit(1)
            if let subtitle = item.subject.subtitle(with: titlePreference) {
              Text(subtitle)
                .lineLimit(1)
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            Label(item.subject.type.description, systemImage: item.subject.type.icon)
              .lineLimit(1)
              .font(.footnote)
              .foregroundStyle(.secondary)
            Text(item.subject.info ?? "")
              .font(.caption)
              .lineLimit(1)
              .foregroundStyle(.secondary)
            Divider()
          }
          HFlow {
            ForEach(item.positions) { position in
              HStack {
                BorderView {
                  Text(position.type.cn).font(.caption)
                }
              }
              .foregroundStyle(.secondary)
              .lineLimit(1)
            }
          }
        }
        Spacer(minLength: 0)
      }
    }
  }
}
