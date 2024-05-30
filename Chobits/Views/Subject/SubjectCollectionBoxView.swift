//
//  SubjectCollectionBoxView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/2.
//

import SwiftData
import SwiftUI

struct SubjectCollectionBoxView: View {
  let subjectId: UInt
  let collection: UserSubjectCollectionDTO?

  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient

  @State private var collectionType: CollectionType
  @State private var rate: UInt8
  @State private var comment: String
  @State private var priv: Bool
  @State private var tags: [String]
  @State private var tagsInput: String
  @State private var updating: Bool = false

  @Query
  private var subjects: [Subject]
  private var subject: Subject? { subjects.first }

  init(subjectId: UInt, collection: UserSubjectCollectionDTO?) {
    self.subjectId = subjectId
    self.collection = collection
    if let collection = collection {
      self.collectionType = collection.type
      self.rate = collection.rate
      self.comment = collection.comment ?? ""
      self.priv = collection.private
      self.tags = collection.tags
      self.tagsInput = collection.tags.joined(separator: ",")
    } else {
      self.collectionType = .do
      self.rate = 0
      self.comment = ""
      self.priv = false
      self.tags = []
      self.tagsInput = ""
    }
    _subjects = Query(
      filter: #Predicate<Subject> {
        $0.subjectId == subjectId
      })
  }

  var recommendedTags: [String] {
    guard let subject = subject else { return [] }
    return subject.tags.sorted(by: { $0.count > $1.count }).prefix(15).map { $0.name }
  }

  var buttonText: String {
    if collection == nil {
      return priv ? "悄悄地添加" : "添加"
    } else {
      return priv ? "悄悄地更新" : "更新"
    }
  }

  func update() {
    self.updating = true
    Task {
      do {
        try await chii.updateSubjectCollection(
          sid: subjectId,
          type: collectionType,
          rate: rate,
          comment: comment,
          priv: priv,
          tags: tags
        )
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
      } catch {
        notifier.alert(error: error)
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
        if let collection = collection {
          Text("上次更新：\(collection.updatedAt)").font(.caption).foregroundStyle(.secondary)
        }

        Picker("Collection Type", selection: $collectionType) {
          ForEach(CollectionType.allTypes()) { ct in
            Text("\(ct.description(type: subject?.typeEnum))").tag(ct)
          }
        }
        .pickerStyle(.segmented)

        VStack(alignment: .leading) {
          HStack(alignment: .top) {
            Text("我的评价:")
            if rate > 0 {
              Text("\(rate.ratingDescription)\(rate)").foregroundStyle(.red)
            }
            if rate == 10 {
              Text("(请谨慎评价)").foregroundStyle(.red)
            }
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
                  rate = UInt8(idx)
                }
            }
          }

          Text("标签 (使用半角空格或逗号隔开，至多10个)")
            .padding(.top, 10)
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
            .padding(.horizontal, 5)
            .padding(.vertical, 5)
            .overlay {
              RoundedRectangle(cornerRadius: 5)
                .stroke(.secondary.opacity(0.2), lineWidth: 1)
                .padding(.horizontal, -2)
                .padding(.vertical, -2)
            }
          HStack(alignment: .top) {
            Text("常用标签").font(.footnote).foregroundStyle(.secondary)
            FlowStack {
              ForEach(recommendedTags, id: \.self) { tag in
                Button {
                  self.tagsInput += " " + tag
                } label: {
                  Text(tag)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .overlay {
                  RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.secondary, lineWidth: 1)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                }
              }
            }
          }

          Text("吐槽")
          TextField("吐槽", text: $comment, axis: .vertical)
            .multilineTextAlignment(.leading)
            .lineLimit(5, reservesSpace: true)
            .padding(.horizontal, 5)
            .padding(.vertical, 5)
            .overlay {
              RoundedRectangle(cornerRadius: 5)
                .stroke(.secondary.opacity(0.2), lineWidth: 1)
                .padding(.horizontal, -2)
                .padding(.vertical, -2)
            }
        }
        Spacer()
      }
      .disabled(updating)
      .animation(.default, value: priv)
      .animation(.default, value: rate)
      .padding()
    }
  }
}

#Preview {
  let container = mockContainer()

  container.mainContext.insert(UserSubjectCollection.previewBook)

  let collection = UserSubjectCollection.previewAnime
  let subject = Subject.previewAnime

  container.mainContext.insert(collection)
  container.mainContext.insert(subject)

  return SubjectCollectionBoxView(
    subjectId: subject.subjectId,
    collection: collection.item
  )
  .environmentObject(Notifier())
  .environment(ChiiClient(container: container, mock: .anime))
  .modelContainer(container)
}
