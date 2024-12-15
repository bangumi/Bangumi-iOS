import SwiftData
import SwiftUI

struct PersonCastsView: View {
  @ObservableModel var person: Person

  @State private var loaded: Bool = false
  @State private var loading: Bool = false

  func load() {
    if loading || loaded { return }
    loading = true
    Task {
      do {
        let resp = try await Chii.shared.getPersonCasts(person.personId, limit: 5)
        person.casts.append(contentsOf: resp.data)
      } catch {
        Notifier.shared.alert(error: error)
      }
      loading = false
      loaded = true
    }
  }

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("最近出演角色")
          .foregroundStyle(person.casts.count > 0 ? .primary : .secondary)
          .font(.title3)
          .onAppear(perform: load)
        if loading {
          ProgressView()
        }
        Spacer()
        if person.casts.count > 0 {
          NavigationLink(value: NavDestination.personCastList(person.personId)) {
            Text("更多角色 »").font(.caption)
          }.buttonStyle(.navLink)
        }
      }
      Divider()
    }.padding(.top, 5)
    VStack {
      ForEach(person.casts) { item in
        CardView {
          PersonCastItemView(item: item)
        }
      }
    }
    .padding(.bottom, 8)
    .animation(.default, value: person.casts)
  }
}

#Preview {
  let container = mockContainer()
  let person = Person.preview
  container.mainContext.insert(person)

  return NavigationStack {
    ScrollView {
      LazyVStack(alignment: .leading) {
        PersonCastsView(person: person)
          .modelContainer(container)
      }.padding()
    }
  }
}
