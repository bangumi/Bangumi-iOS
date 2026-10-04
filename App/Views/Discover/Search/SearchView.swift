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
  let onGoRemote: () -> Void

  var body: some View {
    ScrollView {
      VStack {
        switch searchType {
        case .subject:
          if remote {
            SearchSubjectView(text: text, subjectType: subjectType)
          } else {
            SearchSubjectLocalView(text: text, subjectType: subjectType, onGoRemote: onGoRemote)
          }
        case .character:
          if remote {
            SearchCharacterView(text: text)
          } else {
            SearchCharacterLocalView(text: text, onGoRemote: onGoRemote)
          }
        case .person:
          if remote {
            SearchPersonView(text: text)
          } else {
            SearchPersonLocalView(text: text, onGoRemote: onGoRemote)
          }
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 8)
    }
  }
}
