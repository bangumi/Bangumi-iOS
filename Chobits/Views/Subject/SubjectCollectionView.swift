import OSLog
import SwiftData
import SwiftUI

struct SubjectCollectionView: View {
  @Environment(\.modelContext) var modelContext

  @Environment(Subject.self) var subject

  @State private var edit: Bool = false

  var tags: String {
    subject.interest.tags.joined(separator: " / ")
  }

  var body: some View {
    Section {
      if subject.interest.type != 0 {
        VStack(alignment: .leading) {
          BorderView(color: .linkText, padding: 5) {
            HStack {
              Spacer()
              if subject.interest.private {
                Image(systemName: "lock")
              }
              Label(
                subject.interest.typeEnum.message(type: subject.typeEnum),
                systemImage: subject.interest.typeEnum.icon
              )
              StarsView(score: Float(subject.interest.rate), size: 16)
              Spacer()
            }.foregroundStyle(.linkText)
          }
          .padding(5)
          .onTapGesture {
            edit.toggle()
          }

          if !tags.isEmpty {
            Text(tags)
              .padding(2)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
          Divider()
          if !subject.interest.comment.isEmpty {
            CardView {
              Text(subject.interest.comment)
                .padding(2)
                .font(.footnote)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
                .foregroundStyle(.secondary)
            }
          }

          if subject.typeEnum == .book {
            SubjectBookChaptersView(mode: .large)
              .environment(subject)
          }
        }
      } else {
        VStack(alignment: .leading) {
          BorderView(color: .linkText, padding: 5) {
            HStack {
              Spacer()
              Label("未收藏", systemImage: "plus")
                .foregroundStyle(.secondary)
              Spacer()
            }.foregroundStyle(.linkText)
          }
          .padding(5)
          .onTapGesture {
            edit.toggle()
          }
        }
      }
    }
    .sheet(
      isPresented: $edit,
      content: {
        SubjectCollectionBoxView()
          .environment(subject)
          .presentationDragIndicator(.visible)
          .presentationDetents(.init([.medium, .large]))
      }
    )
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewBook
  container.mainContext.insert(subject)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectCollectionView()
        .environment(subject)
    }.padding()
  }.modelContainer(container)
}
