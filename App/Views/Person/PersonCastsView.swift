import SwiftUI

struct PersonCastsView: View {
  let personId: Int
  let casts: [PersonCastDTO]

  @Environment(\.theme) private var theme

  var body: some View {
    if theme.isClassic {
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
    } else {
      VStack(spacing: 2) {
        ThemedSectionHeader("最近出演角色") {
          if casts.count > 0 {
            NavigationLink(value: NavDestination.personCastList(personId)) {
              Text("更多角色 »").font(.caption)
            }.buttonStyle(.navigation)
          }
        }
        ThemedDivider()
      }.padding(.top, 5)
    }
    VStack {
      ForEach(casts) { item in
        PersonCastItemView(item: item)
      }
    }
    .padding(.bottom, 8)
  }
}
