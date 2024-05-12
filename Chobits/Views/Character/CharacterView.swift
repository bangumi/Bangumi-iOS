//
//  CharacterView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/9.
//

import OSLog
import SwiftData
import SwiftUI

let INFOBOX_NAME_CN_KEYS: [String] = ["简体中文名", "中文名"]
let INFOBOX_IGNORE_KEYS: [String] = ["简体中文名", "中文名", "声优"]

struct CharacterView: View {
  var characterId: UInt

  @AppStorage("shareDomain") var shareDomain: String = ShareDomain.chii.label
  @AppStorage("isolationMode") var isolationMode: Bool = false

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient

  @State private var refreshed: Bool = false
  @State private var coverDetail = false
  @State private var showSummary: Bool = false

  @Query
  private var characters: [Character]
  private var character: Character? { characters.first }

  init(characterId: UInt) {
    self.characterId = characterId
    let predicate = #Predicate<Character> {
      $0.id == characterId
    }
    _characters = Query(filter: predicate, sort: \Character.id)
  }

  var shareLink: URL {
    URL(string: "https://\(shareDomain)/character/\(characterId)")!
  }

  var nameCn: String {
    guard let character = character else {
      return ""
    }
    for item in character.infobox {
      if INFOBOX_NAME_CN_KEYS.contains(item.key) {
        if case .string(let val) = item.value {
          return val
        }
      }
    }
    return ""
  }

  func refresh() async {
    if refreshed { return }
    refreshed = true

    do {
      try await chii.loadCharacter(characterId)
      try await chii.db.save()
    } catch {
      notifier.alert(error: error)
      return
    }
  }

  func shouldShowToggle(geometry: GeometryProxy) -> Bool {
    let lines = Int(
      geometry.size.height / UIFont.preferredFont(forTextStyle: .body).lineHeight)
    if lines < 5 {
      return false
    }
    return true
  }

  var body: some View {
    Section {
      if let character = character {
        ScrollView(showsIndicators: false) {
          LazyVStack(alignment: .leading) {

            /// title
            Text(character.name)
              .font(.title2.bold())
              .multilineTextAlignment(.leading)
            HStack(alignment: .bottom) {
              if !nameCn.isEmpty {
                Text(nameCn)
                  .font(.footnote)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
              }
              if character.locked {
                Label("", systemImage: "lock")
                  .foregroundStyle(.red)
              }
              Spacer()
              if !isolationMode {
                Label("评论: \(character.stat.comments)", systemImage: "bubble")
                  .font(.footnote)
                  .foregroundStyle(Color("LinkTextColor"))
              }
            }

            /// header
            HStack(alignment: .top) {
              ImageView(img: character.images.medium, width: 100, height: 150, alignment: .top)
                .onTapGesture {
                  coverDetail.toggle()
                }
                .sheet(isPresented: $coverDetail) {
                  ImageView(img: character.images.large, width: 0, height: 0)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.fraction(0.8)])
                }
              VStack(alignment: .leading) {
                HStack{
                  Label(character.typeEnum.description, systemImage: character.typeEnum.icon)
                    .foregroundStyle(.secondary)
                  Spacer()
                  Text("收藏: \(character.stat.collects)").foregroundStyle(.secondary)
                }
                ForEach(character.infobox, id: \.key) { item in
                  HStack(alignment: .top) {
                    if !INFOBOX_IGNORE_KEYS.contains(item.key) {
                      Text("\(item.key):")
                      switch item.value {
                      case .string(let val):
                        Text(val).foregroundStyle(.secondary)
                      case .list(let vals):
                        VStack(alignment: .leading) {
                          if item.key == "别名" {
                            ForEach(vals, id: \.k) { val in
                              if let valk = val.k {
                                Text("\(valk): \(val.v)").foregroundStyle(.secondary)
                              } else {
                                Text("\(val.v)").foregroundStyle(.secondary)
                              }
                            }
                          } else {
                            ForEach(vals, id: \.v) { val in
                              if let valk = val.k {
                                Text("\(valk): \(val.v)").foregroundStyle(.secondary)
                              } else {
                                Text("\(val.v)").foregroundStyle(.secondary)
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
              .padding(.leading, 2)
              .font(.footnote)
            }

            /// summary
            Section {
              Text(character.summary)
                .font(.footnote)
                .padding(.bottom, 16)
                .multilineTextAlignment(.leading)
                .lineLimit(5)
                .sheet(isPresented: $showSummary) {
                  ScrollView {
                    LazyVStack(alignment: .leading) {
                      Text("简介").font(.title3).padding(.vertical, 10)
                      Text(character.summary)
                        .textSelection(.enabled)
                        .multilineTextAlignment(.leading)
                        .presentationDragIndicator(.visible)
                        .presentationDetents([.medium, .large])
                      Spacer()
                    }
                  }.padding()
                }
                .overlay(
                  GeometryReader { geometry in
                    if shouldShowToggle(geometry: geometry) {
                      Button(action: {
                        showSummary.toggle()
                      }) {
                        Text("more...")
                          .font(.caption)
                          .foregroundStyle(Color("LinkTextColor"))
                      }
                      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                  }
                )
            }

            /// related subjects
            CharacterSubjectsView(characterId: characterId)
          }
        }.padding(.horizontal, 8)
      } else {
        NotFoundView()
      }
    }
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        ShareLink(item: shareLink) {
          Label("Share", systemImage: "square.and.arrow.up")
        }
      }
    }
    .navigationTitle(character?.name ?? "角色")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      Task(priority: .background) {
        await refresh()
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let character = Character.preview
  container.mainContext.insert(character)
  container.mainContext.insert(Subject.previewAnime)
  container.mainContext.insert(Subject.previewBook)

  return NavigationStack {
    CharacterView(characterId: character.id)
      .environmentObject(Notifier())
      .environment(ChiiClient(container: container, mock: .anime))
      .modelContainer(container)
  }
}
