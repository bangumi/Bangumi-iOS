import PhotosUI
import SwiftUI
import UIKit

private enum WikiImagePayload {
  static func base64(from item: PhotosPickerItem, maxBytes: Int = 4 * 1024 * 1024) async throws
    -> String
  {
    guard let data = try await item.loadTransferable(type: Data.self) else {
      throw ChiiError(message: "无法读取图片")
    }
    if data.count <= maxBytes {
      return data.base64EncodedString()
    }
    guard let image = UIImage(data: data) else {
      throw ChiiError(message: "图片超过 4MB")
    }
    for quality in stride(from: 0.9, through: 0.2, by: -0.1) {
      if let compressed = image.jpegData(compressionQuality: quality), compressed.count <= maxBytes {
        return compressed.base64EncodedString()
      }
    }
    throw ChiiError(message: "图片压缩后仍超过 4MB")
  }
}

struct SubjectWikiCoversView: View {
  let subjectId: Int

  @AppStorage("isAuthenticated") private var isAuthenticated = false
  @AppStorage("profile") private var profile: Profile = Profile()

  @State private var coverList: SubjectCoverListDTO?
  @State private var selectedPhoto: PhotosPickerItem?
  @State private var loading = false
  @State private var uploading = false
  @State private var updatingVote: Int?

  private var canEditCovers: Bool {
    isAuthenticated && profile.canEditSubjectWiki
  }

  private func load() async {
    if loading {
      return
    }
    loading = true
    defer { loading = false }
    do {
      coverList = try await WikiService.getSubjectCovers(subjectId)
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  private func upload(_ item: PhotosPickerItem?) async {
    guard let item else {
      return
    }
    uploading = true
    defer { uploading = false }
    do {
      let payload = try await WikiImagePayload.base64(from: item)
      try await WikiService.uploadSubjectCover(subjectId: subjectId, content: payload)
      Notifier.shared.notify(message: "封面已上传")
      await load()
    } catch {
      Notifier.shared.alert(error: error)
    }
    selectedPhoto = nil
  }

  private func toggleVote(_ cover: SubjectCoverDTO) async {
    if updatingVote != nil {
      return
    }
    updatingVote = cover.id
    defer { updatingVote = nil }
    do {
      if cover.voted == true {
        try await WikiService.unvoteSubjectCover(subjectId: subjectId, imageId: cover.id)
      } else {
        try await WikiService.voteSubjectCover(subjectId: subjectId, imageId: cover.id)
      }
      await load()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    List {
      if loading {
        ProgressView()
      }

      if let current = coverList?.current {
        Section("当前封面") {
          SubjectCoverRowView(cover: current, isUpdating: false, onVote: nil)
        }
      }

      Section("候选封面") {
        ForEach(coverList?.covers ?? []) { cover in
          SubjectCoverRowView(
            cover: cover,
            isUpdating: updatingVote == cover.id,
            onVote: canEditCovers
              ? {
                Task {
                  await toggleVote(cover)
                }
              }
              : nil
          )
        }
      }
    }
    .task {
      await load()
    }
    .refreshable {
      await load()
    }
    .navigationTitle("条目封面")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if canEditCovers {
        ToolbarItem(placement: .topBarTrailing) {
          PhotosPicker(selection: $selectedPhoto, matching: .images) {
            Label("上传", systemImage: "square.and.arrow.up")
          }
          .disabled(uploading)
        }
      }
    }
    .onChange(of: selectedPhoto) { _, newValue in
      Task {
        await upload(newValue)
      }
    }
  }
}

private struct SubjectCoverRowView: View {
  let cover: SubjectCoverDTO
  let isUpdating: Bool
  let onVote: (() -> Void)?

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      ImageView(img: cover.thumbnail)
        .imageStyle(width: 72, height: 102)
        .imageType(.subject)

      VStack(alignment: .leading, spacing: 6) {
        Text("#\(cover.id)")
          .font(.headline)
        if let creator = cover.creator {
          NavigationLink(value: NavDestination.user(creator.username)) {
            Text("by \(creator.nickname)")
              .font(.footnote)
          }
          .buttonStyle(.navigation)
        }
        Text(cover.raw)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .lineLimit(2)
          .textSelection(.enabled)
      }

      Spacer()

      if let onVote {
        Button {
          onVote()
        } label: {
          if isUpdating {
            ProgressView()
              .controlSize(.small)
          } else {
            Image(systemName: cover.voted == true ? "hand.thumbsup.fill" : "hand.thumbsup")
          }
        }
        .buttonStyle(.borderless)
      }
    }
  }
}

struct WikiPortraitUploadSheet: View {
  @Environment(\.dismiss) private var dismiss

  let kind: WikiEntityKind
  let entityId: Int
  let onSave: () -> Void

  @State private var selectedPhoto: PhotosPickerItem?
  @State private var imageBase64: String?
  @State private var imageLoadToken = 0
  @State private var loadingImage = false
  @State private var submitting = false

  private var title: String {
    switch kind {
    case .person:
      return "上传人物肖像"
    case .character:
      return "上传角色肖像"
    default:
      return "上传图片"
    }
  }

  private func loadImage(_ item: PhotosPickerItem?, token: Int) async {
    guard imageLoadToken == token else {
      return
    }
    guard let item else {
      imageBase64 = nil
      loadingImage = false
      return
    }
    imageBase64 = nil
    loadingImage = true
    defer {
      if imageLoadToken == token {
        loadingImage = false
      }
    }
    do {
      let payload = try await WikiImagePayload.base64(from: item)
      guard imageLoadToken == token else {
        return
      }
      imageBase64 = payload
    } catch {
      guard imageLoadToken == token else {
        return
      }
      imageBase64 = nil
      Notifier.shared.alert(error: error)
    }
  }

  private func submit() async {
    guard let imageBase64, !submitting else {
      return
    }
    submitting = true
    defer { submitting = false }
    do {
      switch kind {
      case .person:
        _ = try await WikiService.uploadPersonPortrait(personId: entityId, imageBase64: imageBase64)
        try? await PersonRepository.loadPerson(entityId)
      case .character:
        _ = try await WikiService.uploadCharacterPortrait(
          characterId: entityId,
          imageBase64: imageBase64
        )
        try? await CharacterRepository.loadCharacter(entityId)
      default:
        return
      }
      Notifier.shared.notify(message: "肖像已上传")
      onSave()
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    SheetView(title: title, closeDisabled: submitting, applyFormStyle: true) {
      Form {
        Section {
          PhotosPicker(selection: $selectedPhoto, matching: .images) {
            Label("选择图片", systemImage: "photo")
          }
          if loadingImage {
            ProgressView()
          } else if imageBase64 != nil {
            Label("图片已准备好", systemImage: "checkmark.circle")
          }
        }
      }
      .onChange(of: selectedPhoto) { _, newValue in
        imageLoadToken += 1
        let token = imageLoadToken
        Task {
          await loadImage(newValue, token: token)
        }
      }
    } controls: {
      Button {
        Task {
          await submit()
        }
      } label: {
        Label("上传", systemImage: "square.and.arrow.up")
      }
      .disabled(submitting || imageBase64 == nil)
    }
  }
}
