import SwiftData
import SwiftUI

struct PersonCastsView: View {
  var personId: Int

  @State private var loaded: Bool = false
  @State private var loading: Bool = false
  @State private var casts: [PersonCastDTO] = []

  func load() {
    if loading || loaded { return }
    loading = true
    Task {
      do {
        let resp = try await Chii.shared.getPersonCasts(personId, limit: 5)
        casts.append(contentsOf: resp.data)
      } catch {
        Notifier.shared.alert(error: error)
      }
      loading = false
      loaded = true
    }
  }

  var body: some View {
    Divider()
    HStack {
      Text("最近出演角色")
        .foregroundStyle(casts.count > 0 ? .primary : .secondary)
        .font(.title3)
        .onAppear(perform: load)
      if loading {
        ProgressView()
      }
      Spacer()
      if casts.count > 0 {
        NavigationLink(value: NavDestination.personCastList(personId: personId)) {
          Text("更多角色 »").font(.caption).foregroundStyle(.linkText)
        }.buttonStyle(.plain)
      }
    }
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
        PersonCastsView(personId: person.personId)
          .modelContainer(container)
      }
    }.padding()
  }
}
