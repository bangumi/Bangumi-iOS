import Flow
import OSLog
import SwiftData
import SwiftUI

struct SubjectCollectionView: View {
  @Environment(\.modelContext) var modelContext

  @Environment(Subject.self) var subject

  @State private var edit: Bool = false

  var body: some View {
    Section {
      if let interest = subject.interest {
        VStack(alignment: .leading) {
          BorderView(color: .linkText, padding: 5) {
            HStack {
              Spacer()
              if interest.private {
                Image(systemName: "lock")
              }
              Label(
                interest.type.message(type: subject.typeEnum),
                systemImage: interest.type.icon
              )
              StarsView(score: Float(interest.rate), size: 16)
              Spacer()
            }.foregroundStyle(.linkText)
          }
          .padding(5)
          .onTapGesture {
            edit.toggle()
          }
          HStack {
            Spacer()
            Text("\(interest.updatedAt.datetimeDisplay)")
              + Text(" / \(interest.updatedAt.date, style: .relative)前")
              .foregroundStyle(.secondary)
            Spacer()
          }
          .monospacedDigit()
          .font(.footnote)
          Divider()

          HFlow {
            ForEach(interest.tags, id: \.self) { tag in
              BorderView {
                Text(tag)
                  .font(.footnote)
                  .foregroundStyle(.secondary)
              }
            }
          }
          if !interest.comment.isEmpty {
            CardView {
              Text(interest.comment)
                .padding(2)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
            }
          }

          if subject.typeEnum == .book {
            SubjectBookChaptersView(mode: .large)
              .environment(subject)
          }
        }
      } else {
        VStack {
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
    .sheet(isPresented: $edit) {
      SubjectCollectionBoxView()
        .environment(subject)
        .presentationDragIndicator(.visible)
        .presentationDetents(.init([.medium, .large]))
    }
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
