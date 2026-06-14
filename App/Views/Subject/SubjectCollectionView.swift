import Flow
import OSLog
import SwiftUI

struct SubjectCollectionView: View {
  let subject: SubjectDTO
  let reload: () async -> Void

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
                interest.type.message(type: subject.type),
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
              + Text(" / \(interest.updatedAt.relativeAgeDisplay)")
              .foregroundStyle(.secondary)
            Spacer()
          }
          .monospacedDigit()
          .font(.footnote)

          if !interest.tags.isEmpty {
            HFlow {
              ForEach(interest.tags, id: \.self) { tag in
                BorderView {
                  Text(tag)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
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

          if subject.type == .book {
            SubjectBookChaptersView(subject: subject, mode: .large, reload: reload)
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
      SubjectCollectionBoxView(subjectId: subject.id)
        .presentationDragIndicator(.visible)
        .onDisappear {
          Task {
            await reload()
          }
        }
    }
  }
}
