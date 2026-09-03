import Flow
import SwiftUI

struct SubjectCollectionBoxView: View {
  let subjectId: Int
  var onSaved: (() async -> Void)? = nil

  @AppStorage("autoCompleteProgress") var autoCompleteProgress: Bool = false
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Environment(\.dismiss) private var dismiss
  @Environment(\.theme) private var theme

  @FocusState private var tagsFocused: Bool

  @State private var subject: SubjectDTO? = nil
  @State private var ctype: CollectionType = .none
  @State private var rate: Int = 0
  @State private var comment: String = ""
  @State private var priv: Bool = false
  @State private var tags: Set<String> = Set()
  @State private var tagsInput: String = ""
  @State private var updating: Bool = false

  init(subjectId: Int, initialSubject: SubjectDTO? = nil, onSaved: (() async -> Void)? = nil) {
    self.subjectId = subjectId
    self.onSaved = onSaved
    _subject = State(initialValue: initialSubject)
    _ctype = State(initialValue: initialSubject?.interest?.type ?? .none)
    _rate = State(initialValue: initialSubject?.interest?.rate ?? 0)
    _comment = State(initialValue: initialSubject?.interest?.comment ?? "")
    _priv = State(initialValue: initialSubject?.interest?.private ?? false)
    _tags = State(initialValue: Set(initialSubject?.interest?.tags ?? []))
  }

  var subjectTitle: String {
    subject?.title(with: titlePreference) ?? ""
  }

  var recommendedTags: [String] {
    return subject?.tags.sorted(by: { $0.count > $1.count }).prefix(15).map { $0.name } ?? []
  }

  var buttonText: String {
    if (subject?.ctypeEnum ?? .none) != .none {
      return priv ? "悄悄地更新" : "更新"
    } else {
      return priv ? "悄悄地添加" : "添加"
    }
  }

  var ratingComment: String {
    if rate == 10 {
      return "\(rate.ratingDescription) \(rate) (请谨慎评价)"
    }
    if rate > 0 {
      return "\(rate.ratingDescription) \(rate)"
    }
    return ""
  }

  var submitDisabled: Bool {
    return ctype == .none || comment.count > 380
  }

  func populateEditor(with loadedSubject: SubjectDTO) {
    subject = loadedSubject
    populateCollectionFields(from: loadedSubject.interest)
  }

  func populateCollectionFields(from interest: SubjectInterest?) {
    if let interest {
      ctype = interest.type
      rate = interest.rate
      comment = interest.comment
      priv = interest.private
      tags = Set(interest.tags)
    } else {
      ctype = .none
      rate = 0
      comment = ""
      priv = false
      tags = []
    }
  }

  func loadIfNeeded() async {
    guard subject == nil else {
      return
    }

    updating = true
    defer {
      updating = false
    }

    do {
      let db = try await AppContext.shared.getDB()
      if let cachedSubject = try await db.getSubjectDTO(subjectId) {
        populateEditor(with: cachedSubject)
        return
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
    do {
      let loadedSubject = try await SubjectRepository.loadSubject(subjectId)
      populateEditor(with: loadedSubject)
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  func updateTags() {
    let inputTags = tagsInput.split(separator: " ").map { String($0) }
    withAnimation(.default) {
      tags.formUnion(inputTags)
      tagsInput = ""
    }
  }

  func update() {
    withAnimation(.default) {
      self.updating = true
    }
    Task {
      defer {
        withAnimation(.default) {
          self.updating = false
        }
      }
      do {
        try await SubjectRepository.updateSubjectCollection(
          subjectId: subjectId,
          type: ctype,
          rate: rate,
          comment: comment,
          priv: priv,
          tags: Array(tags.sorted().prefix(10)),
          progress: autoCompleteProgress
        )
        await onSaved?()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  var body: some View {
    SheetView(
      title: subjectTitle,
      size: .both,
      closeDisabled: updating,
      controlsPlacement: .primaryAction
    ) {
      ScrollView {
        if theme.isClassic {
          classicBody
        } else {
          glassBody
        }
      }
      .task(loadIfNeeded)
    } controls: {
      Button {
        withAnimation(.default) {
          priv.toggle()
        }
      } label: {
        Image(systemName: priv ? "lock.fill" : "lock.circle.dotted")
      }
      .adaptiveButtonStyle(priv ? .borderedProminent : .plain)
      .disabled(updating)
      .sensoryFeedback(.selection, trigger: priv)
    }
  }

  private var classicBody: some View {
    VStack {
      HStack {
        Button(action: update) {
          Spacer()
          Text(buttonText)
          Spacer()
        }
        .buttonStyle(.borderedProminent)
        .disabled(submitDisabled)
      }

      if let interest = subject?.interest, interest.updatedAt > 0 {
        Section {
          Text("上次更新：\(interest.updatedAt.datetimeDisplay)")
            + Text(" / \(interest.updatedAt.relativeAgeDisplay)")
            .foregroundStyle(.secondary)
        }
        .monospacedDigit()
        .font(.caption)
      }

      Picker("CollectionType", selection: $ctype.animated()) {
        ForEach(CollectionType.allTypes()) { ct in
          Text("\(ct.description(subject?.type ?? .anime))").tag(ct)
        }
      }
      .pickerStyle(.segmented)

      VStack(alignment: .leading) {
        HStack(alignment: .top) {
          Text("我的评价:")
          Text(ratingComment)
            .foregroundStyle(rate > 0 ? .red : .secondary)
        }
        HStack {
          Image(systemName: "star.slash")
            .resizable()
            .foregroundStyle(.secondary)
            .frame(width: 20, height: 20)
            .onTapGesture {
              withAnimation(.default) {
                rate = 0
              }
            }
          ForEach(1..<11) { idx in
            Image(systemName: rate >= idx ? "star.fill" : "star")
              .resizable()
              .foregroundStyle(.orange)
              .frame(width: 20, height: 20)
              .onTapGesture {
                withAnimation(.default) {
                  rate = Int(idx)
                }
              }
          }
        }

        Text("标签 (使用半角空格或逗号隔开，至多10个)")
          .font(.footnote)

        HFlow(alignment: .center, spacing: 4) {
          ForEach(Array(tags.sorted().prefix(10)), id: \.self) { tag in
            BorderView(padding: 2) {
              Button {
                withAnimation(.default) {
                  _ = tags.remove(tag)
                }
              } label: {
                Label(tag, systemImage: "xmark.circle")
                  .labelStyle(.compact)
              }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
          }
        }.padding(.top, 2)

        BorderView(color: .secondary.opacity(0.2), padding: 4) {
          HStack {
            TextField("标签", text: $tagsInput)
              .autocorrectionDisabled()
              .textInputAutocapitalization(.never)
              .onSubmit {
                updateTags()
              }
            Button {
              updateTags()
            } label: {
              Image(systemName: "plus.circle")
            }.disabled(tagsInput.isEmpty)
          }
        }

        VStack(alignment: .leading, spacing: 2) {
          Text("常用标签:").font(.footnote).foregroundStyle(.secondary)
          HFlow(alignment: .center, spacing: 2) {
            ForEach(recommendedTags, id: \.self) { tag in
              Button {
                withAnimation(.default) {
                  _ = tags.insert(tag)
                }
              } label: {
                if tags.contains(tag) {
                  Label(tag, systemImage: "checkmark.circle")
                    .labelStyle(.compact)
                } else {
                  Label(tag, systemImage: "plus.circle")
                    .labelStyle(.compact)
                }
              }
              .disabled(tags.contains(tag))
              .font(.caption)
              .lineLimit(1)
              .padding(.vertical, 2)
              .padding(.horizontal, 4)
              .foregroundStyle(.secondary.opacity(tags.contains(tag) ? 0.6 : 1))
              .background(.secondary.opacity(tags.contains(tag) ? 0.3 : 0.1))
              .cornerRadius(5)
              .padding(1)
            }
          }
        }

        Text("吐槽")
        TextInputView(type: "吐槽", text: $comment)
          .textInputStyle(wordLimit: 380)
      }
      Spacer()
    }
    .disabled(updating)
    .padding(.horizontal)
  }

  private var glassBody: some View {
    VStack(alignment: .leading, spacing: GlassForm.blockSpacing) {
      Button(action: update) {
        Text(buttonText)
      }
      .buttonStyle(.themedProminent)
      .disabled(submitDisabled)

      if let interest = subject?.interest, interest.updatedAt > 0 {
        GlassFormMetaRow {
          Text("上次更新 \(interest.updatedAt.datetimeDisplay)")
            .monospacedDigit()
          Text(interest.updatedAt.relativeAgeDisplay)
            .monospacedDigit()
          Spacer(minLength: 0)
        }
      }

      GlassSegmented(selection: $ctype.animated(), items: CollectionType.allTypes()) { ct in
        Text(ct.description(subject?.type ?? .anime))
      }

      ratingBlock

      GlassFormSection(title: "标签") {
        VStack(alignment: .leading, spacing: GlassForm.metaSpacing) {
          tagsField
          GlassFormMetaRow {
            Text("使用半角空格或逗号隔开，至多 10 个")
          }
          if !tags.isEmpty {
            selectedTags
          }
        }
      }

      if !recommendedTags.isEmpty {
        GlassFormSection(title: "常用标签") {
          HFlow(spacing: 6) {
            ForEach(recommendedTags, id: \.self) { tag in
              Button {
                withAnimation(.default) {
                  _ = tags.insert(tag)
                }
              } label: {
                Label(tag, systemImage: tags.contains(tag) ? "checkmark.circle" : "plus.circle")
                  .labelStyle(.compact)
                  .lineLimit(1)
              }
              .buttonStyle(ThemedChipStyle(isSelected: false))
              .disabled(tags.contains(tag))
              .opacity(tags.contains(tag) ? 0.4 : 1)
            }
          }
        }
      }

      GlassFormSection(title: "吐槽") {
        TextInputView(type: "吐槽", text: $comment)
          .textInputStyle(wordLimit: 380)
      }
    }
    .disabled(updating)
    .padding(.horizontal, theme.metrics.screenPadding)
    .padding(.top, GlassForm.topInset)
    .padding(.bottom, theme.metrics.screenPadding)
  }

  private var ratingBlock: some View {
    VStack(alignment: .leading, spacing: GlassForm.labelSpacing) {
      HStack(spacing: 6) {
        Text("我的评价")
          .font(.subheadline.weight(.bold))
          .foregroundStyle(theme.sectionHeader)
        Text(ratingComment)
          .font(.caption)
          .foregroundStyle(rate > 0 ? theme.accentDeep : theme.tertiaryText)
        Spacer(minLength: 0)
        Button {
          withAnimation(.default) {
            rate = 0
          }
        } label: {
          Image(systemName: "star.slash")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(theme.tertiaryText)
        }
        .buttonStyle(.plain)
        .disabled(rate == 0)
        .opacity(rate == 0 ? 0.4 : 1)
        .accessibilityLabel("清除评分")
      }
      HStack(spacing: GlassForm.starSpacing) {
        ForEach(1..<11) { idx in
          Image(systemName: rate >= idx ? "star.fill" : "star")
            .resizable()
            .scaledToFit()
            .foregroundStyle(rate >= idx ? theme.star : theme.disabled)
            .frame(width: GlassForm.starSize, height: GlassForm.starSize)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
              withAnimation(.default) {
                rate = idx
              }
            }
        }
        Spacer(minLength: 0)
      }
      .frame(height: GlassForm.controlHeight)
    }
  }

  private var tagsField: some View {
    HStack(spacing: 8) {
      TextField("", text: $tagsInput, prompt: Text("标签").foregroundStyle(theme.placeholder))
        .focused($tagsFocused)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .foregroundStyle(theme.body)
        .onSubmit {
          updateTags()
        }
      Button {
        updateTags()
      } label: {
        Image(systemName: "plus.circle.fill")
          .font(.title3)
          .foregroundStyle(tagsInput.isEmpty ? theme.disabled : theme.accent)
      }
      .buttonStyle(.plain)
      .disabled(tagsInput.isEmpty)
    }
    .themedFieldChrome(focused: tagsFocused, height: GlassForm.controlHeight)
  }

  private var selectedTags: some View {
    HFlow(spacing: 6) {
      ForEach(Array(tags.sorted().prefix(10)), id: \.self) { tag in
        Button {
          withAnimation(.default) {
            _ = tags.remove(tag)
          }
        } label: {
          Label(tag, systemImage: "xmark.circle")
            .labelStyle(.compact)
            .lineLimit(1)
        }
        .buttonStyle(ThemedChipStyle(isSelected: true))
      }
    }
  }
}
