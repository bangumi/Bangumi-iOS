import OSLog
import SwiftData
import SwiftUI

struct CollectionsView: View {

  @State private var width: CGFloat = 0

  var body: some View {
    ScrollView(showsIndicators: false) {
      LazyVStack(alignment: .leading) {
        ForEach(SubjectType.allTypes) { stype in
          VStack {
            HStack {
              Text("我的\(stype.description)").font(.title3)
              Spacer()
              NavigationLink(value: NavDestination.collectionList(stype)) {
                Text("更多 »")
                  .font(.caption)
              }.buttonStyle(.navLink)
            }.padding(.top, 8)
            CollectionSubjectTypeView(stype: stype, width: width)
          }.padding(.top, 5)
        }
      }.padding(.horizontal, 8)
    }
    .navigationTitle("我的收藏")
    .navigationBarTitleDisplayMode(.inline)
    .onGeometryChange(for: CGSize.self) { proxy in
      proxy.size
    } action: { newSize in
      if self.width != newSize.width {
        self.width = newSize.width
      }
    }
  }
}
