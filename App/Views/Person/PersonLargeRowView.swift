import SwiftData
import SwiftUI

struct PersonLargeRowView: View {
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Bindable var person: Person

  var body: some View {
    HStack(spacing: 8) {
      ImageView(img: person.images?.resize(.r200))
        .imageStyle(width: 90, height: 90)
        .imageType(.person)
        .imageNSFW(person.nsfw)
        .imageNavLink(person.link)
      VStack(alignment: .leading, spacing: 4) {
        Text(person.title(with: titlePreference))
          .font(.headline)
          .lineLimit(1)
        if let subtitle = person.subtitle(with: titlePreference) {
          Text(subtitle)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        Text(person.info)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .lineLimit(2)
        if person.comment > 0 {
          Label("评论: \(person.comment)", systemImage: "bubble")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
      Spacer()
    }
  }
}
