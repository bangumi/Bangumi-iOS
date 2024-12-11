import Flow
import SwiftUI

struct InfoboxView: View {
  let infobox: Infobox

  var body: some View {
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
}

struct InfoboxHeaderView: View {
  let infobox: Infobox

  var body: some View {
    VStack(alignment: .leading) {
      ForEach(infobox.header()) { item in
        HStack(alignment: .top) {
          Text("\(item.key):")
          VStack(alignment: .leading) {
            ForEach(item.values) { value in
              HStack {
                if let k = value.k {
                  Text("\(k):")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
                Text(value.v)
                  .textSelection(.enabled)
                  .lineLimit(1)
              }
            }
          }
        }.fixedSize(horizontal: false, vertical: true)
      }
    }
    .font(.footnote)
    .frame(maxHeight: 90, alignment: .top)
    .clipped()
  }
}

#Preview {
  ScrollView {
    InfoboxView(infobox: Subject.previewAnime.infobox)
  }
}
