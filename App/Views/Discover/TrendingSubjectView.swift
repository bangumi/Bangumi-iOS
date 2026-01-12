import SwiftData
import SwiftUI

struct TrendingSubjectView: View {
  let width: CGFloat

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @State private var loaded: Bool = false

  func load() async {
    if loaded {
      return
    }
    do {
      try await Chii.shared.loadTrendingSubjects()
      loaded = true
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    LazyVStack(spacing: 24) {
      ForEach(SubjectType.allTypes) { st in
        TrendingSubjectTypeView(type: st, width: width - 16)
      }
    }
    .padding(.horizontal, 8)
    .task(load)
  }
}

struct TrendingSubjectTypeView: View {
  let type: SubjectType
  let width: CGFloat

  @AppStorage("subjectImageQuality") var subjectImageQuality: ImageQuality = .high
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @Query private var trending: [TrendingSubject]
  var items: [TrendingSubjectDTO] { trending.first?.items ?? [] }

  init(type: SubjectType, width: CGFloat) {
    self.type = type
    self.width = width
    let descriptor = FetchDescriptor<TrendingSubject>(
      predicate: #Predicate { $0.type == type.rawValue }
    )
    self._trending = Query(descriptor)
  }

  var columnCount: Int {
    let count = Int(width / 320)
    return max(count, 1)
  }

  var largeCardWidth: CGFloat {
    var w = CGFloat(320)
    w = (width + 8) / CGFloat(columnCount) - 8
    return max(w, 300)
  }

  var smallCardWidth: CGFloat {
    let w = (width + 8) / CGFloat(columnCount * 2) - 8
    return max(w, 150)
  }

  var largeItems: [TrendingSubjectDTO] {
    return Array(items.prefix(columnCount))
  }

  var smallItems: [TrendingSubjectDTO] {
    return Array(items.dropFirst(largeItems.count))
  }

  var body: some View {
    VStack(spacing: 8) {
      if items.isEmpty {
        ProgressView()
      } else {
        VStack(spacing: 5) {
          HStack {
            Text("\(type.description)").font(.title)
            Spacer()
            NavigationLink(value: NavDestination.subjectBrowsing(type)) {
              Text("更多 »")
            }.buttonStyle(.navigation)
          }
        }
        HStack {
          ForEach(largeItems) { item in
            ImageView(img: item.subject.images?.resize(subjectImageQuality.largeSize))
              .imageStyle(width: largeCardWidth, height: type.coverHeight(for: largeCardWidth))
              .imageType(.subject)
              .imageCaption {
                HStack {
                  VStack(alignment: .leading) {
                    if item.count > 10 {
                      Text("\(item.count) 人关注")
                        .font(.caption)
                    }
                    Text(item.subject.title(with: titlePreference))
                      .multilineTextAlignment(.leading)
                      .truncationMode(.middle)
                      .lineLimit(2)
                      .font(.body)
                      .bold()
                  }
                  Spacer(minLength: 0)
                }.padding(8)
              }
              .imageNavLink(item.subject.link)
              .subjectPreview(item.subject)
          }
        }
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack {
            ForEach(smallItems) { item in
              ImageView(img: item.subject.images?.resize(subjectImageQuality.mediumSize))
                .imageStyle(width: smallCardWidth, height: type.coverHeight(for: smallCardWidth))
                .imageType(.subject)
                .imageCaption {
                  HStack {
                    VStack(alignment: .leading) {
                      if item.count > 10 {
                        Text("\(item.count) 人关注")
                          .font(.caption)
                      }
                      Text(item.subject.title(with: titlePreference))
                        .multilineTextAlignment(.leading)
                        .truncationMode(.middle)
                        .lineLimit(2)
                        .font(.footnote)
                        .bold()
                    }
                    Spacer(minLength: 0)
                  }.padding(4)
                }
                .imageNavLink(item.subject.link)
                .subjectPreview(item.subject)
            }
          }.scrollTargetLayout()
        }
        .scrollClipDisabled()
        .scrollTargetBehavior(.viewAligned)
      }
    }.animation(.default, value: items)
  }
}
