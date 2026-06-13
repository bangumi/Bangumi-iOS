import OSLog
import SwiftUI

struct CollectionsView: View {

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading) {
        ForEach(SubjectType.allTypes) { stype in
          CollectionSubjectTypeView(stype: stype)
            .padding(.top, 5)
        }
      }.padding(.horizontal, 8)
    }
    .navigationTitle("我的收藏")
    .navigationBarTitleDisplayMode(.inline)
  }
}
