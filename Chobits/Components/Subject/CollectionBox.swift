//
//  CollectionBox.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/2.
//

import SwiftData
import SwiftUI

struct CollectionBox: View {
  private var subject: Subject
  private var collection: UserSubjectCollection?
  @Binding var isPresented: Bool

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) private var modelContext

  @State private var collectionType: CollectionType
  @State private var rate: UInt8
  @State private var comment: String
  @State private var priv: Bool
  @State private var tags: [String]
  @State private var tagsInput: String

  @State private var updating: Bool = false

  init(subject: Subject, collection: UserSubjectCollection?, isPresented: Binding<Bool>) {
    self.subject = subject
    self.collection = collection
    self._isPresented = isPresented
    self.collectionType = collection?.type ?? .do
    self.rate = collection?.rate ?? 0
    self.comment = collection?.comment ?? ""
    self.priv = collection?.private ?? false
    let ctags = collection?.tags ?? []
    self.tags = ctags
    self.tagsInput = ctags.joined(separator: " ")
  }

  var recommendedTags: [String] {
    subject.tags.sorted(by: { $0.count > $1.count }).prefix(15).map { $0.name }
  }

  func update() {
    self.updating = true
    let actor = BackgroundActor(modelContainer: modelContext.container)
    Task {
      do {
        let resp = try await chii.updateSubjectCollection(
          sid: subject.id,
          type: collectionType,
          rate: rate,
          comment: comment,
          priv: priv,
          tags: tags
        )
        try await actor.insert(collections: [resp])
        self.isPresented = false
      } catch {
        notifier.alert(message: "\(error)")
      }
      self.updating = false
    }
  }

  var body: some View {
    ScrollView {
      VStack {
        Picker("Collection Type", selection: $collectionType) {
          ForEach(CollectionType.boxTypes()) { ct in
            Text("\(ct.description(type: subject.type))")
          }
        }
        .pickerStyle(.segmented)

        HStack {
          Button(action: update) {
            Spacer()
            Text(priv ? "悄悄更新" : "更新")
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
  CollectionBox(subject: .previewAnime, collection: .previewAnime, isPresented: .constant(true))
}
