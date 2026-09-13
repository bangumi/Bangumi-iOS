import OSLog
import SwiftUI

enum SearchType {
  case subject
  case character
  case person
}

struct SearchView: View {
  @Binding var text: String
  @Binding var remote: Bool
  @Binding var searchType: SearchType
  @Binding var subjectType: SubjectType

  var body: some View {
    ScrollView {
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
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 8)
    }
  }
}
