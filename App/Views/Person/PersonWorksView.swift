import Flow
import SwiftUI

struct PersonWorksView: View {
  let personId: Int
  let works: [PersonWorkDTO]

  @Environment(\.theme) private var theme

  var body: some View {
    if theme.isClassic {
      VStack(spacing: 2) {
        HStack(alignment: .bottom) {
          Text("最近参与")
            .foregroundStyle(works.count > 0 ? .primary : .secondary)
            .font(.title3)
          Spacer()
          if works.count > 0 {
            NavigationLink(value: NavDestination.personWorkList(personId)) {
              Text("更多作品 »").font(.caption)
            }.buttonStyle(.navigation)
          }
        }
        Divider()
      }.padding(.top, 5)
    } else {
      VStack(spacing: 2) {
        ThemedSectionHeader("最近参与") {
          if works.count > 0 {
            NavigationLink(value: NavDestination.personWorkList(personId)) {
              Text("更多作品 »").font(.caption)
            }.buttonStyle(.navigation)
          }
        }
        ThemedDivider()
      }.padding(.top, 5)
    }
    VStack {
      ForEach(works) { item in
        PersonWorksItemView(item: item)
      }
    }
    .padding(.bottom, 8)
  }
}
