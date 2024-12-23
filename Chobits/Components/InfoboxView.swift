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
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Image(systemName: "info.circle").foregroundStyle(.secondary)
      }
    }
  }
}

struct InfoboxHeaderView: View {
  let infobox: Infobox

  var body: some View {
    HStack {
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
      .frame(maxHeight: 72, alignment: .top)
      .clipped()
    }
    Spacer()
    Image(systemName: "chevron.right")
      .font(.title3)
      .foregroundColor(.linkText)
  }
}

#Preview {
  ScrollView {
    InfoboxView(title: "", infobox: Subject.previewAnime.infobox)
  }
}
