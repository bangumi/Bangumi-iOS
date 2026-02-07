import BBCode
import Flow
import SwiftData
import SwiftUI

struct SubjectSummaryView: View {
  @Bindable var subject: Subject

  var metaTags: [Tag] {
    var result: [Tag] = []
    for name in subject.metaTags {
      if let tag = subject.tags.first(where: { $0.name == name }) {
        result.append(tag)
      } else {
        result.append(Tag(name: name, count: 0))
      }
    }
    return result
  }

  var tags: [Tag] {
    let count = max(20 - metaTags.count, 0)
    let result = subject.tags.sorted { $0.count > $1.count }.filter { !metaTags.contains($0) }
      .prefix(count)
    return Array(result)
  }

  private func tagLink(
    _ tag: Tag,
    color: Color,
    tagsCat: SubjectTagsCategory
  ) -> some View {
    NavigationLink(value: NavDestination.subjectTagBrowsing(subject.typeEnum, tag.name, tagsCat)) {
      BorderView(color: color, padding: 3, cornerRadius: 16) {
        HStack(spacing: 2) {
          Text(tag.name)
            .font(.footnote)
            .foregroundStyle(.linkText)
            .lineLimit(1)
          Text("\(tag.count)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
      }
    }
    .buttonStyle(.scale)
    .padding(1)
  }

  var body: some View {
    VStack(alignment: .leading) {
      BBCodeView(subject.summary, textSize: 14)
        .textSelection(.enabled)
        .padding(2)
        .tint(.linkText)
      CardView {
        HStack {
          HFlow(alignment: .center, spacing: 3) {
            ForEach(metaTags, id: \.name) { tag in
              tagLink(tag, color: .linkText, tagsCat: .meta)
            }
            ForEach(tags, id: \.name) { tag in
              tagLink(tag, color: .secondary.opacity(0.2), tagsCat: .subject)
            }
          }
          Spacer(minLength: 0)
        }
        .animation(.default, value: tags)
        .animation(.default, value: metaTags)
      }
    }
  }
}
