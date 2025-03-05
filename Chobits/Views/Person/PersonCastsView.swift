import SwiftData
import SwiftUI

struct PersonCastsView: View {
  let personId: Int
  let casts: [PersonCastDTO]

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("最近出演角色")
          .foregroundStyle(casts.count > 0 ? .primary : .secondary)
          .font(.title3)
        Spacer()
        if casts.count > 0 {
          NavigationLink(value: NavDestination.personCastList(personId)) {
            Text("更多角色 »").font(.caption)
          }.buttonStyle(.navigation)
        }
      }
      Divider()
    }.padding(.top, 5)
    VStack {
      ForEach(casts) { item in
        CardView {
          PersonCastItemView(item: item)
        }
      }
    }
    .padding(.bottom, 8)
    .animation(.default, value: casts)
  }
}

#Preview {
  let container = mockContainer()
  let person = Person.preview
  container.mainContext.insert(person)

  return NavigationStack {
    ScrollView {
      LazyVStack(alignment: .leading) {
        PersonCastsView(personId: person.personId, casts: person.casts)
          .modelContainer(container)
      }.padding()
    }
  }
}
