import Flow
import SwiftData
import SwiftUI

struct SubjectCollectionBoxView: View {
  @AppStorage("profile") var profile: Profile = Profile()

  @Environment(\.modelContext) var modelContext
  @Environment(\.dismiss) private var dismiss
  @Environment(Subject.self) var subject
  @Environment(UserSubjectCollection.self) var collection

  @State private var collectionType: CollectionType = .do
  @State private var rate: Int = 0
  @State private var comment: String = ""
  @State private var priv: Bool = false
  @State private var tags: Set<String> = Set()
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
    self.tags = Set(collection.tags)
  }

  func updateTags() {
    let inputTags = tagsInput.split(separator: " ").map { String($0) }
    tags.formUnion(inputTags)
    tagsInput = ""
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
          tags: Array(tags.sorted().prefix(10))
        )
        try await Chii.shared.loadSubjectCollection(
          username: profile.username, subjectId: subject.subjectId)
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
        }
        .disabled(collectionType == .none)
        .padding(.vertical, 5)
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
            .font(.footnote)
            .padding(.top, 10)

          HFlow(alignment: .center, spacing: 4) {
            ForEach(Array(tags.sorted().prefix(10)), id: \.self) { tag in
              BorderView(padding: 2) {
                Button {
                  tags.remove(tag)
                } label: {
                  Label(tag, systemImage: "xmark.circle")
                    .labelStyle(.compact)
                }
              }
              .font(.caption)
              .foregroundStyle(.secondary)
            }
          }.padding(.top, 2)

          BorderView(color: .secondary.opacity(0.2), padding: 4) {
            HStack {
              TextField("标签", text: $tagsInput)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit {
                  updateTags()
                }
              Button {
                updateTags()
              } label: {
                Image(systemName: "plus.circle")
              }.disabled(tagsInput.isEmpty)
            }
          }

          VStack(alignment: .leading, spacing: 2) {
            Text("常用标签:").font(.footnote).foregroundStyle(.secondary)
            HFlow(alignment: .center, spacing: 2) {
              ForEach(recommendedTags, id: \.self) { tag in

                  Button {
                    tags.insert(tag)
                  } label: {
                    if tags.contains(tag) {
                      Label(tag, systemImage: "checkmark.circle")
                        .labelStyle(.compact)
                    } else {
                      Label(tag, systemImage: "plus.circle")
                        .labelStyle(.compact)
                    }
                  }
                  .disabled(tags.contains(tag))
                  .font(.caption)
                  .lineLimit(1)
                  .padding(.vertical, 2)
                  .padding(.horizontal, 4)
                  .foregroundStyle(.secondary.opacity(tags.contains(tag) ? 0.6 : 1))
                  .background(.secondary.opacity(tags.contains(tag) ? 0.3 : 0.1))
                  .cornerRadius(5)
                  .padding(1)
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
