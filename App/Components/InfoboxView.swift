import Flow
import SwiftUI

struct InfoboxView: View {
  let title: String
  let infobox: Infobox

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading) {
        ForEach(infobox) { item in
          HStack(alignment: .top) {
            Text("\(item.key):").bold()
            VStack(alignment: .leading) {
              ForEach(item.values) { value in
                HStack(alignment: .top) {
                  if let k = value.k {
                    Text("\(k):")
                      .foregroundStyle(.secondary)
                      .lineLimit(1)
                  }
                  Text(value.v)
                    .textSelection(.enabled)
                }
              }
            }
          }
          Divider()
        }
      }.padding()
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  ScrollView {
    InfoboxView(title: "", infobox: Subject.previewAnime.infobox)
  }
}
