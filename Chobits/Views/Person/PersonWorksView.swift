import Flow
import SwiftData
import SwiftUI

struct PersonWorksView: View {
  let personId: Int
  let works: [PersonWorkDTO]

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("最近参与")
          .foregroundStyle(works.count > 0 ? .primary : .secondary)
          .font(.title3)
        Spacer()
        if works.count > 0 {
          NavigationLink(value: NavDestination.personWorkList(personId)) {
            Text("更多作品 »").font(.caption)
          }.buttonStyle(.navLink)
        }
      }
      Divider()
    }.padding(.top, 5)
    VStack {
      ForEach(works) { item in
        CardView {
          HStack(alignment: .top) {
            NavigationLink(value: NavDestination.subject(item.subject.id)) {
              ImageView(img: item.subject.images?.common)
                .imageStyle(width: 60, height: 60)
                .imageType(.subject)
            }
            VStack(alignment: .leading) {
              VStack(alignment: .leading) {
                NavigationLink(value: NavDestination.subject(item.subject.id)) {
                  Text(item.subject.name)
                    .font(.callout)
                    .lineLimit(1)
                }
                if item.subject.nameCN.isEmpty {
                  Label(item.subject.type.description, systemImage: item.subject.type.icon)
                    .lineLimit(1)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                } else {
                  Label(item.subject.nameCN, systemImage: item.subject.type.icon)
                    .lineLimit(1)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                Text(item.subject.info)
                  .font(.caption)
                  .lineLimit(1)
                  .foregroundStyle(.secondary)
                Divider()
              }.frame(height: 60)
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
            Spacer()
          }.buttonStyle(.navLink)
        }
      }
    }
    .padding(.bottom, 8)
    .animation(.default, value: works)
  }
}

#Preview {
  let container = mockContainer()
  let person = Person.preview
  container.mainContext.insert(person)

  return NavigationStack {
    ScrollView {
      LazyVStack(alignment: .leading) {
        PersonWorksView(personId: person.personId, works: person.works)
          .modelContainer(container)
      }.padding()
    }
  }
}
