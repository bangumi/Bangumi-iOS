import SwiftUI

struct PersonSmallView: View {
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  let person: SlimPersonDTO
  let isCollected: Bool

  var body: some View {
    EmbedCard {
      HStack {
        ImageView(img: person.images?.resize(.r200))
          .imageStyle(width: 50, height: 50, alignment: .top)
          .imageType(.person)
          .imageNSFW(person.nsfw)
          .imageCollectedStatus(isCollected)
        VStack(alignment: .leading) {
          Text(person.title(with: titlePreference))
          if let info = person.info, !info.isEmpty {
            Text(info)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }.lineLimit(1)
        Spacer(minLength: 0)
      }
    }
    .frame(height: 58)
  }

  init(person: SlimPersonDTO, isCollected: Bool = false) {
    self.person = person
    self.isCollected = isCollected
  }
}
