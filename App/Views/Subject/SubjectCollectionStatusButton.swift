import SwiftUI

struct SubjectCollectionStatusButton: View {
  let subjectId: Int
  let subjectType: SubjectType
  let collectionType: CollectionType

  @AppStorage("isAuthenticated") private var isAuthenticated: Bool = false
  @State private var showCollectionBox = false

  private var isCollected: Bool {
    collectionType != .none
  }

  private var title: String {
    isCollected ? collectionType.description(subjectType) : "收藏"
  }

  private var icon: String {
    isCollected ? collectionType.icon : "plus"
  }

  private var foregroundStyle: Color {
    isCollected ? collectionType.color : .secondary
  }

  var body: some View {
    if isAuthenticated || isCollected {
      Button {
        showCollectionBox = true
      } label: {
        Label(title, systemImage: icon)
          .labelStyle(.compact)
          .foregroundStyle(foregroundStyle)
          .contentShape(RoundedRectangle(cornerRadius: 6))
      }
      .font(.caption)
      .controlSize(.mini)
      .adaptiveButtonStyle(.bordered)
      .disabled(!isAuthenticated)
      .accessibilityLabel(isCollected ? "编辑收藏状态：\(title)" : "添加收藏")
      .sheet(isPresented: $showCollectionBox) {
        SubjectCollectionBoxView(subjectId: subjectId)
      }
    }
  }
}

extension View {
  func subjectCollectionStatusOverlay(
    subjectId: Int,
    subjectType: SubjectType,
    collectionType: CollectionType
  ) -> some View {
    overlay(alignment: .trailing) {
      SubjectCollectionStatusButton(
        subjectId: subjectId,
        subjectType: subjectType,
        collectionType: collectionType
      )
      .padding(.trailing, 4)
    }
  }
}

#Preview {
  HStack {
    SubjectCollectionStatusButton(
      subjectId: Subject.previewAnime.subjectId,
      subjectType: .anime,
      collectionType: .none
    )
    SubjectCollectionStatusButton(
      subjectId: Subject.previewAnime.subjectId,
      subjectType: .anime,
      collectionType: .doing
    )
  }
  .padding()
  .modelContainer(mockContainer())
}
