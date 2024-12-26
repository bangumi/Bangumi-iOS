import SwiftData
import SwiftUI

struct SubjectTinyView: View {
  let subject: SlimSubjectDTO

  var body: some View {
    BorderView(color: .secondary.opacity(0.2), cornerRadius: 8) {
      HStack {
        ImageView(img: subject.images?.grid)
          .imageStyle(width: 32, height: 32)
          .imageType(.subject)
        VStack(alignment: .leading) {
          Text("\(subject.nameCN.isEmpty ? subject.name : subject.nameCN)")
            .lineLimit(1)
        }
        Spacer()
      }.padding(4)
    }
    .background(.ultraThinMaterial)
    .frame(height: 40)
    .contextMenu {
      NavigationLink(value: NavDestination.subject(subject.id)) {
        Label("查看详情", systemImage: "magnifyingglass")
      }
    } preview: {
      SubjectCardView(subject: subject)
        .padding()
        .frame(idealWidth: 360)
    }
  }
}

struct SubjectSmallView: View {
  let subject: SlimSubjectDTO

  var body: some View {
    BorderView(color: .secondary.opacity(0.2), cornerRadius: 8) {
      HStack {
        ImageView(img: subject.images?.common)
          .imageStyle(width: 48, height: 64)
          .imageType(.subject)
        VStack(alignment: .leading) {
          Text("\(subject.nameCN.isEmpty ? subject.name : subject.nameCN)")
            .lineLimit(1)
          Text(subject.info)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
        Spacer()
      }.padding(4)
    }
    .background(.ultraThinMaterial)
    .frame(height: 72)
    .contextMenu {
      NavigationLink(value: NavDestination.subject(subject.id)) {
        Label("查看详情", systemImage: "magnifyingglass")
      }
      if subject.type == .anime || subject.type == .real {
        NavigationLink(value: NavDestination.episodeList(subject.id)) {
          Label("章节列表", systemImage: "list.bullet")
        }
      }
    } preview: {
      SubjectCardView(subject: subject)
        .padding()
        .frame(idealWidth: 360)
    }
  }
}

struct SubjectCardView: View {
  let subject: SlimSubjectDTO

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      HStack(alignment: .top) {
        ImageView(img: subject.images?.common)
          .imageStyle(width: 72, height: 96)
          .imageType(.subject)
        VStack(alignment: .leading) {
          Text(subject.name)
            .font(.headline)
            .lineLimit(1)
          if !subject.nameCN.isEmpty {
            Text(subject.nameCN)
              .font(.subheadline)
              .lineLimit(1)
          }
          Spacer()
          Text(subject.info)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(2)
          Spacer()
        }
        Spacer()
      }
    }
  }
}
