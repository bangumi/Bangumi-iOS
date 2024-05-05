//
//  CollectionBox.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/2.
//

import SwiftData
import SwiftUI

struct SubjectCollectionBox: View {
  let subject: Subject
  let collection: UserSubjectCollection?
  @Binding var isPresented: Bool

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) private var modelContext

  @State private var collectionType: CollectionType = .do
  @State private var rate: UInt8 = 0
  @State private var comment: String = ""
  @State private var priv: Bool = false
  @State private var tags: [String] = []
  @State private var tagsInput: String = ""
  @State private var updating: Bool = false

  init(subject: Subject, collection: UserSubjectCollection?, isPresented: Binding<Bool>) {
    self.subject = subject
    self._isPresented = isPresented
    self.collection = collection
    if let collect = collection {
      self.collectionType = collect.typeEnum
      self.rate = collect.rate
      self.comment = collect.comment
      self.priv = collect.priv
      let ctags = collect.tags
      self.tags = ctags
      self.tagsInput = ctags.joined(separator: " ")
    }
  }

  var recommendedTags: [String] {
    return subject.tags.sorted(by: { $0.count > $1.count }).prefix(15).map { $0.name }
  }

  func update() {
    self.updating = true
    let actor = BackgroundActor(container: modelContext.container)
    Task {
      do {
        let item = try await chii.updateSubjectCollection(
          sid: subject.id,
          type: collectionType,
          rate: rate,
          comment: comment,
          priv: priv,
          tags: tags
        )
        let collect = UserSubjectCollection(item: item)
        await actor.insert(data: collect)
        try await actor.save()
        self.isPresented = false
      } catch {
        notifier.alert(error: error)
      }
      self.updating = false
    }
  }

  var body: some View {
    ScrollView {
      VStack {
        Picker("Collection Type", selection: $collectionType) {
          ForEach(CollectionType.boxTypes()) { ct in
            Text("\(ct.description(type: subject.typeEnum))").tag(ct)
          }
        }
        .pickerStyle(.segmented)

        HStack {
          Button(action: update) {
            Spacer()
            Text(priv ? "悄悄地更新" : "更新")
            Spacer()
          }
          .buttonStyle(.borderedProminent)
          Toggle(isOn: $priv) {
            Image(systemName: priv ? "lock" : "lock.open")
          }
          .toggleStyle(.button)
          .buttonStyle(.borderedProminent)
          .frame(width: 40)
        }.padding(.vertical, 5)
        if let collect = collection {
          Text("上次更新：\(collect.updatedAt)").font(.caption).foregroundStyle(.secondary)
        }

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
          .font(.callout)
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
            .font(.footnote)
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
            .font(.callout)
            .monospaced()
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

          Text("吐槽").font(.footnote)
          TextField("吐槽", text: $comment, axis: .vertical)
            .font(.callout)
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
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: UserSubjectCollection.self, configurations: config)
  let collection = UserSubjectCollection.previewBook
  container.mainContext.insert(UserSubjectCollection.previewBook)

  return SubjectCollectionBox(
    subject: .previewBook,
    collection: .previewBook,
    isPresented: .constant(true)
  )
  .environmentObject(Notifier())
  .environmentObject(ChiiClient(mock: .book))
  .modelContainer(container)
}
