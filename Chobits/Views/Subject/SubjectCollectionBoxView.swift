import Flow
import SwiftData
import SwiftUI

struct SubjectCollectionBoxView: View {
  @Environment(\.modelContext) var modelContext
  @Environment(\.dismiss) private var dismiss
  @Environment(Subject.self) var subject
  @Environment(UserSubjectCollection.self) var collection

  @State private var collectionType: CollectionType = .do
  @State private var rate: Int = 0
  @State private var comment: String = ""
  @State private var priv: Bool = false
  @State private var tags: [String] = []
  @State private var tagsInput: String = ""

  @State private var updating: Bool = false

  var recommendedTags: [String] {
    return subject.tags.sorted(by: { $0.count > $1.count }).prefix(15).map { $0.name }
  }

  var buttonText: String {
    if collection.typeEnum == .none {
      return priv ? "悄悄地添加" : "添加"
    } else {
      return priv ? "悄悄地更新" : "更新"
    }
  }

  var ratingComment: String {
    if rate == 10 {
      return "\(rate.ratingDescription) \(rate) (请谨慎评价)"
    }
    if rate > 0 {
      return "\(rate.ratingDescription) \(rate)"
    }
    return ""
  }

  func load() {
    self.collectionType = collection.typeEnum
    self.rate = collection.rate
    self.comment = collection.comment
    self.priv = collection.priv
    self.tags = collection.tags
    self.tagsInput = collection.tags.joined(separator: " ")
  }

  func update() {
    self.updating = true
    Task {
      do {
        try await Chii.shared.updateSubjectCollection(
          subjectId: subject.subjectId,
          type: collectionType,
          rate: rate,
          comment: comment,
          priv: priv,
          tags: tags
        )
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
      } catch {
        Notifier.shared.alert(error: error)
      }
      self.updating = false
    }
  }

  var body: some View {
    ScrollView {
      VStack {
        HStack {
          Button(action: update) {
            Spacer()
            Text(buttonText)
            Spacer()
          }
          .buttonStyle(.borderedProminent)
          Toggle(isOn: $priv) {
            Image(systemName: priv ? "lock" : "lock.open")
          }
          .toggleStyle(.button)
          .buttonStyle(.borderedProminent)
          .frame(width: 40)
          .sensoryFeedback(.selection, trigger: priv)
        }.padding(.vertical, 5)
        if collection.updatedAt.timeIntervalSince1970 > 0 {
          Text("上次更新：\(collection.updatedAt.formatted(date: .complete, time: .complete))")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Picker("Collection Type", selection: $collectionType) {
          ForEach(CollectionType.allTypes()) { ct in
            Text("\(ct.description(subject.typeEnum))").tag(ct)
          }
        }
        .pickerStyle(.segmented)

        VStack(alignment: .leading) {
          HStack(alignment: .top) {
            Text("我的评价:")
            Text(ratingComment)
              .foregroundStyle(rate > 0 ? .red : .secondary)
          }
          .padding(.top, 10)
          HStack {
            Image(systemName: "star.slash")
              .resizable()
              .foregroundStyle(.secondary)
              .frame(width: 20, height: 20)
              .onTapGesture {
                rate = 0
              }
            ForEach(1..<11) { idx in
              Image(systemName: rate >= idx ? "star.fill" : "star")
                .resizable()
                .foregroundStyle(.orange)
                .frame(width: 20, height: 20)
                .onTapGesture {
                  rate = Int(idx)
                }
            }
          }

          Text("标签 (使用半角空格或逗号隔开，至多10个)")
            .padding(.top, 10)
          BorderView(color: .secondary.opacity(0.2), padding: 4) {
            TextField("标签", text: $tagsInput)
              .onChange(of: tagsInput) { _, new in
                var tagSet: Set<String> = Set()
                for tag in new.components(separatedBy: " ") {
                  if !tag.isEmpty {
                    tagSet.insert(tag.trimmingCharacters(in: .whitespacesAndNewlines))
                  }
                }
                tags = Array(tagSet.sorted())
                if tags.count > 10 {
                  tags = Array(tags[0..<10])
                }
              }
          }
          HStack(alignment: .top) {
            Text("常用标签").font(.footnote).foregroundStyle(.secondary)
            HFlow(alignment: .center, spacing: 2) {
              ForEach(recommendedTags, id: \.self) { tag in
                BorderView {
                  Button {
                    self.tagsInput += " " + tag
                  } label: {
                    Text(tag)
                  }
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
                }
                .padding(2)
              }
            }
          }

          Text("吐槽")
          BorderView(color: .secondary.opacity(0.2), padding: 4) {
            TextField("吐槽", text: $comment, axis: .vertical)
              .multilineTextAlignment(.leading)
              .scrollDisabled(true)
              .lineLimit(5...)
          }
        }
        Spacer()
      }
      .onAppear(perform: load)
      .disabled(updating)
      .animation(.default, value: priv)
      .animation(.default, value: rate)
      .padding()
    }
  }
}

#Preview {
  let container = mockContainer()

  let collection = UserSubjectCollection.previewBook
  let subject = Subject.previewBook

  container.mainContext.insert(collection)
  container.mainContext.insert(subject)
  collection.subject = subject

  return SubjectCollectionBoxView()
    .environment(subject)
    .environment(collection)
    .modelContainer(container)
}
