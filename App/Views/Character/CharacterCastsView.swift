import SwiftData
import SwiftUI

struct CharacterCastsView: View {
  let characterId: Int
  let casts: [CharacterCastDTO]

  var body: some View {
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("出演作品")
          .foregroundStyle(casts.count > 0 ? .primary : .secondary)
          .font(.title3)
        Spacer()
        if casts.count > 0 {
          NavigationLink(value: NavDestination.characterCastList(characterId)) {
            Text("更多出演 »").font(.caption)
          }.buttonStyle(.navigation)
        }
      }
      Divider()
    }.padding(.top, 5)
    if casts.count == 0 {
      HStack {
        Spacer()
        Text("暂无出演")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
      }.padding(.bottom, 5)
    }
    LazyVStack {
      ForEach(casts, id: \.subject.id) { item in
        VStack {
          CharacterCastItemView(item: item)
          Divider()
        }
      }
    }.animation(.default, value: casts)
  }
}

#Preview {
  NavigationStack {
    ScrollView {
      LazyVStack(alignment: .leading) {
        CharacterCastsView(
          characterId: Character.preview.characterId,
          casts: Character.preview.casts
        )
      }.padding()
    }
  }
}
