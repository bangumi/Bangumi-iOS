import SwiftUI

struct PersonSmallView: View {
  let person: SlimPersonDTO

  var title: String {
    if person.nameCN.isEmpty {
      return person.name
    } else {
      return person.nameCN
    }
  }

  var body: some View {
    BorderView(color: .secondary.opacity(0.2), padding: 4, paddingRatio: 1, cornerRadius: 8) {
      HStack {
        ImageView(img: person.images?.resize(.r200))
          .imageStyle(width: 50, height: 50)
          .imageType(.person)
          .imageNSFW(person.nsfw)
        VStack(alignment: .leading) {
          Text(title)
          if let info = person.info, !info.isEmpty {
            Text(info)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }.lineLimit(1)
        Spacer(minLength: 0)
      }
    }
    .background(.secondary.opacity(0.01))
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .frame(height: 58)
  }
}
