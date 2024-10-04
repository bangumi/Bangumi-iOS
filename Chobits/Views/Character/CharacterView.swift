//
//  CharacterView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/9.
//

import OSLog
import SwiftData
import SwiftUI

struct CharacterView: View {
  var characterId: UInt

  @AppStorage("shareDomain") var shareDomain: String = ShareDomain.chii.label
  @AppStorage("isolationMode") var isolationMode: Bool = false

  @Environment(Notifier.self) private var notifier

  @State private var refreshed: Bool = false
  @State private var coverDetail = false
  @State private var showSummary: Bool = false
  @State private var showInfobox: Bool = false

  @Query
  private var characters: [Character]
  private var character: Character? { characters.first }

  init(characterId: UInt) {
    self.characterId = characterId
    let predicate = #Predicate<Character> {
      $0.characterId == characterId
    }
    _characters = Query(filter: predicate, sort: \Character.characterId)
  }

  var shareLink: URL {
    URL(string: "https://\(shareDomain)/character/\(characterId)")!
  }

  func refresh() async {
    if refreshed { return }
    refreshed = true

    do {
      try await Chii.shared.loadCharacter(characterId)
    } catch {
      notifier.alert(error: error)
      return
    }
  }

  func refreshAll() async {
    do {
      try await Chii.shared.loadCharacter(characterId)
      try await Chii.shared.loadCharacterSubjects(characterId)
      try await Chii.shared.loadCharacterPersons(characterId)
    } catch {
      notifier.alert(error: error)
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
                HStack {
                  Label(character.typeEnum.description, systemImage: character.typeEnum.icon)
                  if character.stat.collects > 0 {
                    Text("(\(character.stat.collects)人收藏)")
                  }
                  Spacer()
                  if character.locked {
                    Label("", systemImage: "lock")
                      .foregroundStyle(.red)
                  }
                  if !isolationMode {
                    Label("评论: \(character.stat.comments)", systemImage: "bubble")
                      .font(.footnote)
                      .foregroundStyle(.linkText)
                  }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                VStack(alignment: .leading) {
                  ForEach(character.infobox, id: \.key) { item in
                    HStack(alignment: .top) {
                      Text("\(item.key):").fixedSize(horizontal: false, vertical: true)
                      switch item.value {
                      case .string(let val):
                        Text(val)
                          .foregroundStyle(.secondary)
                          .textSelection(.enabled)
                          .lineLimit(1)
                      case .list(let vals):
                        VStack(alignment: .leading) {
                          ForEach(vals, id: \.desc) { val in
                            Text(val.desc)
                              .foregroundStyle(.secondary)
                              .textSelection(.enabled)
                              .lineLimit(1)
                          }
                        }
                      }
                    }
                  }
                }
                .font(.footnote)
                .frame(maxHeight: 108, alignment: .top)
                .clipped()
                .sheet(isPresented: $showInfobox) {
                  ScrollView {
                    LazyVStack(alignment: .leading) {
                      Text("资料").font(.title3).padding(.vertical, 10)
                      VStack(alignment: .leading) {
                        ForEach(character.infobox, id: \.key) { item in
                          HStack(alignment: .top) {
                            Text("\(item.key):")
                            switch item.value {
                            case .string(let val):
                              Text(val)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                                .lineLimit(1)
                            case .list(let vals):
                              VStack(alignment: .leading) {
                                ForEach(vals, id: \.desc) { val in
                                  Text(val.desc)
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                                    .lineLimit(1)
                                }
                              }
                            }
                          }
                        }
                      }
                      .presentationDragIndicator(.visible)
                      .presentationDetents([.medium, .large])
                      Spacer()
                    }
                  }.padding()
                }
                Spacer()
                Button(action: {
                  showInfobox.toggle()
                }) {
                  Text("more...")
                    .font(.caption)
                    .foregroundStyle(.linkText)
                }

              }.padding(.leading, 2)
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
                          .foregroundStyle(.linkText)
                      }
                      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
                  }
                )
            }

            /// related subjects
            CharacterSubjectsView(characterId: characterId)
          }
        }
        .padding(.horizontal, 8)
        .refreshable {
          await refreshAll()
        }
      } else {
        NotFoundView()
      }
    }
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        ShareLink(item: shareLink) {
          Label("Share", systemImage: "square.and.arrow.up")
        }
      }
    }
    .navigationTitle(character?.name ?? "角色")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      Task {
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
    CharacterView(characterId: character.characterId)
      .environment(Notifier())
      .modelContainer(container)
  }
}
