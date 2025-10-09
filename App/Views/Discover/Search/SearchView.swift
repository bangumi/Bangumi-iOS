import OSLog
import SwiftData
import SwiftUI

enum SearchType {
  case subject
  case character
  case person
}

struct SearchView: View {
  @Binding var text: String
  @Binding var searching: Bool
  @Binding var remote: Bool

  @State private var searchType: SearchType = .subject
  @State private var subjectType: SubjectType = .none

  var body: some View {
    ScrollView {
      VStack(spacing: 4) {
        HStack(spacing: 4) {
          Picker("SearchType", selection: $searchType) {
            Text("条目").tag(SearchType.subject)
            Text("角色").tag(SearchType.character)
            Text("人物").tag(SearchType.person)
          }.pickerStyle(.segmented)
          Image(systemName: remote ? "globe" : "internaldrive")
            .foregroundColor(remote ? .blue : .green)
            .frame(width: 20)
            .padding(.horizontal, 4)
        }
        if searchType == .subject {
          Picker("Subject Type", selection: $subjectType) {
            Text("全部").tag(SubjectType.none)
            ForEach(SubjectType.allTypes) { type in
              Text(type.description).tag(type)
            }
          }.pickerStyle(.segmented)
        }
      }.padding(.horizontal, 8)
      if text.isEmpty {
        Text("输入关键字搜索")
          .foregroundStyle(.secondary)
          .padding(8)
      } else {
        VStack {
          switch searchType {
          case .subject:
            if remote {
              SearchSubjectView(text: text, subjectType: subjectType)
            } else {
              SearchSubjectLocalView(text: text, subjectType: subjectType)
            }
          case .character:
            if remote {
              SearchCharacterView(text: text)
            } else {
              SearchCharacterLocalView(text: text)
            }
          case .person:
            if remote {
              SearchPersonView(text: text)
            } else {
              SearchPersonLocalView(text: text)
            }
          }
        }.padding(.horizontal, 8)
      }
    }
    .animation(.default, value: searchType)
    .animation(.default, value: subjectType)
    .animation(.default, value: text)
    .onChange(of: searchType) {
      remote = false
    }
    .onChange(of: subjectType) {
      remote = false
    }
  }
}
