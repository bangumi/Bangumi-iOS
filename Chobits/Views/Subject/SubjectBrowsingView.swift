import Flow
import SwiftData
import SwiftUI

enum FilterExpand: String {
  case cat = "cat"
  case series = "series"
  case year = "year"
  case month = "month"
  case sort = "sort"
}

struct SubjectBrowsingView: View {
  let type: SubjectType

  @Environment(\.modelContext) private var modelContext

  @State private var showFilter: Bool = false
  @State private var filterExpand: FilterExpand? = nil
  @State private var filter: SubjectsBrowseFilter = SubjectsBrowseFilter()
  @State private var sort: SubjectSortMode = .rank

  @State private var reloader: Bool = false

  var categories: [PlatformInfo] {
    var categories: [Int: PlatformInfo]
    switch type {
    case .anime:
      categories = SubjectPlatforms.animePlatforms
    case .book:
      categories = SubjectPlatforms.bookPlatforms
    case .game:
      categories = SubjectPlatforms.gamePlatforms
    case .real:
      categories = SubjectPlatforms.realPlatforms
    default:
      categories = [:]
    }
    return Array(categories.values.sorted { $0.id < $1.id })
  }

  func fetchPage(page: Int) async -> PagedDTO<SlimSubjectDTO>? {
    do {
      guard let db = await Chii.shared.db else {
        throw ChiiError.uninitialized
      }
      let resp = try await Chii.shared.getSubjects(
        type: type, sort: sort, filter: filter, page: page)
      for item in resp.data {
        try await db.saveSubject(item)
      }
      try await db.commit()
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading) {
        HFlow {
          Label("筛选", systemImage: "line.3.horizontal.decrease.circle")
          // cat
          if let cat = filter.cat {
            BadgeView(background: .accent) {
              Text(cat.typeCN)
            }
          }

          // series
          if let series = filter.series {
            BadgeView(background: .accent) {
              Text(series ? "系列" : "单行本")
            }
          }

          // tags
          if let tags = filter.tags {
            ForEach(tags, id: \.self) { tag in
              BadgeView(background: .accent) {
                Text(tag)
              }
            }
          }

          // date
          if let year = filter.year {
            if let month = filter.month {
              BadgeView(background: .accent) {
                Text("\(String(year))年\(String(month))月")
              }
            } else {
              BadgeView(background: .accent) {
                Text("\(String(year))年")
              }
            }
          }
        }

        HStack {
          Image(systemName: "arrow.up.arrow.down.circle")
          Text("按")
          BadgeView(background: .accent) {
            Label(sort.description, systemImage: sort.icon)
          }
          Text("排序")
          Spacer()
        }

        Divider()

        SimplePageView(reloader: reloader, nextPageFunc: fetchPage) { subject in
          SubjectItemView(subjectId: subject.id)
        }

      }.padding(.horizontal, 8)
    }
    .animation(.default, value: reloader)
    .animation(.default, value: filter)
    .animation(.default, value: sort)
    .navigationTitle("全部\(type.description)")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showFilter) {
      SubjectBrowsingFilterView(type: type, filter: $filter, categories: categories)
    }
    .onChange(of: showFilter) {
      if !showFilter {
        reloader.toggle()
      }
    }
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        HStack {
          Button {
            showFilter = true
          } label: {
            Image(systemName: "line.3.horizontal.decrease")
          }
          Menu {
            ForEach(SubjectSortMode.allCases, id: \.self) { sortMode in
              Button {
                sort = sortMode
                reloader.toggle()
              } label: {
                Label(sortMode.description, systemImage: sortMode.icon)
              }.disabled(sort == sortMode)
            }
          } label: {
            Image(systemName: "arrow.up.arrow.down")
          }
        }
      }
    }
  }
}

struct SubjectBrowsingFilterView: View {
  let type: SubjectType
  @Binding var filter: SubjectsBrowseFilter
  let categories: [PlatformInfo]

  @Environment(\.dismiss) private var dismiss

  @State private var years: [Int]

  init(
    type: SubjectType,
    filter: Binding<SubjectsBrowseFilter>,
    categories: [PlatformInfo]
  ) {
    self.type = type
    self._filter = filter
    self.categories = categories
    let date = Date()
    let calendar = Calendar.current
    let currentYear = calendar.component(.year, from: date)
    var years: [Int] = []
    for idx in 0...9 {
      years.append(Int(currentYear - idx))
    }
    self._years = State(initialValue: years)
  }

  func catTextColor(_ cat: PlatformInfo?) -> Color {
    if filter.cat?.id == cat?.id {
      return .white
    }
    return .linkText
  }

  func catBackgroundColor(_ cat: PlatformInfo?) -> Color {
    if filter.cat?.id == cat?.id {
      return .accent
    }
    return .clear
  }

  func seriesTextColor(_ series: Bool?) -> Color {
    if filter.series == series {
      return .white
    }
    return .linkText
  }

  func seriesBackgroundColor(_ series: Bool?) -> Color {
    if filter.series == series {
      return .accent
    }
    return .clear
  }

  func updateYears(modifier: Int) {
    years = years.map { $0 + modifier }
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack {

          /// cat
          VStack(alignment: .leading) {
            CardView {
              HStack {
                Text("分类").font(.title3)
                Spacer()
              }
            }
            HFlow {
              Button {
                filter.cat = nil
              } label: {
                BadgeView(background: catBackgroundColor(nil), padding: 5) {
                  Text("全部")
                    .foregroundStyle(catTextColor(nil))
                }
              }.buttonStyle(.scale)
              ForEach(categories) { category in
                Button {
                  filter.cat = category
                } label: {
                  BadgeView(background: catBackgroundColor(category), padding: 5) {
                    Text(category.typeCN)
                      .foregroundStyle(catTextColor(category))
                  }
                }.buttonStyle(.scale)
              }
            }
          }

          /// series
          if type == .book {
            VStack(alignment: .leading) {
              CardView {
                HStack {
                  Text("系列").font(.title3)
                  Spacer()
                }
              }
              HFlow {
                Button {
                  filter.series = nil
                } label: {
                  BadgeView(background: seriesBackgroundColor(nil), padding: 5) {
                    Text("全部")
                      .foregroundStyle(seriesTextColor(nil))
                  }
                }.buttonStyle(.scale)
                Button {
                  filter.series = true
                } label: {
                  BadgeView(background: seriesBackgroundColor(true), padding: 5) {
                    Text("系列")
                      .foregroundStyle(seriesTextColor(true))
                  }
                }.buttonStyle(.scale)
                Button {
                  filter.series = false
                } label: {
                  BadgeView(background: seriesBackgroundColor(false), padding: 5) {
                    Text("单行本")
                      .foregroundStyle(seriesTextColor(false))
                  }
                }.buttonStyle(.scale)
              }
            }
          }

          /// anime tag
          if type == .anime {
            SubjectBrowsingFilterTagView(
              filter: $filter, title: "来源", tags: SubjectAnimeTagSources)
            SubjectBrowsingFilterTagView(
              filter: $filter, title: "类型", tags: SubjectAnimeTagGenres)
            SubjectBrowsingFilterTagView(
              filter: $filter, title: "地区", tags: SubjectAnimeTagAreas)
            SubjectBrowsingFilterTagView(
              filter: $filter, title: "受众", tags: SubjectAnimeTagTargets)
          }

          /// game tag
          if type == .game {
            SubjectBrowsingFilterTagView(
              filter: $filter, title: "类型", tags: SubjectGameTagGenres)
            SubjectBrowsingFilterTagView(
              filter: $filter, title: "受众", tags: SubjectGameTagTargets)
            SubjectBrowsingFilterTagView(
              filter: $filter, title: "分级", tags: SubjectGameTagRatings)
          }

          /// real tag
          if type == .real {
            SubjectBrowsingFilterTagView(
              filter: $filter, title: "题材", tags: SubjectRealTagThemes)
            SubjectBrowsingFilterTagView(
              filter: $filter, title: "地区", tags: SubjectRealTagAreas)
          }

          /// date
          VStack(alignment: .leading) {
            CardView {
              HStack {
                Text("时间").font(.title3)
                Spacer()
              }
            }
            Button {
              filter.year = nil
              filter.month = nil
            } label: {
              HStack {
                Spacer()
                Text("不限年份")
                  .foregroundStyle(filter.year == nil ? .accent : .linkText)
                Spacer()
              }
            }
            LazyVGrid(columns: [
              GridItem(.flexible()),
              GridItem(.flexible()),
              GridItem(.flexible()),
              GridItem(.flexible()),
            ]) {
              Button {
                updateYears(modifier: 10)
              } label: {
                Text("来年们").foregroundStyle(.linkText)
              }
              .buttonStyle(.scale)
              .padding(2)
              ForEach(years, id: \.self) { year in
                Button {
                  filter.year = year
                } label: {
                  if filter.year == year {
                    Text("\(String(year))年").foregroundStyle(.accent)
                  } else {
                    Text("\(String(year))年").foregroundStyle(.linkText)
                  }
                }
                .buttonStyle(.scale)
                .padding(2)
              }
              Button {
                updateYears(modifier: -10)
              } label: {
                Text("往年们").foregroundStyle(.linkText)
              }
              .buttonStyle(.scale)
              .padding(2)
            }.animation(.default, value: years)
            if filter.year != nil {
              Button {
                filter.month = nil
              } label: {
                HStack {
                  Spacer()
                  Text("不限月份")
                    .foregroundStyle(filter.month == nil ? .accent : .linkText)
                  Spacer()
                }
              }
              LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
              ]) {
                ForEach(1..<13) { month in
                  Button {
                    filter.month = Int(month)
                  } label: {
                    if filter.month == month {
                      Text("\(month)月").foregroundStyle(.accent)
                    } else {
                      Text("\(month)月").foregroundStyle(.linkText)
                    }
                  }
                  .buttonStyle(.scale)
                  .padding(2)
                }
              }
            }
          }

        }.padding()
      }
      .animation(.default, value: filter)
      .navigationTitle("筛选")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            dismiss()
          } label: {
            Text("完成")
          }
        }
      }
    }
  }
}

struct SubjectBrowsingFilterTagView: View {
  @Binding var filter: SubjectsBrowseFilter
  let title: String
  let tags: [String]

  func tagTextColor(_ tag: String) -> Color {
    guard let ftags = filter.tags else {
      return .linkText
    }
    if ftags.contains(tag) {
      return .white
    }
    return .linkText
  }

  func tagBackgroundColor(_ tag: String) -> Color {
    guard let ftags = filter.tags else {
      return .clear
    }
    if ftags.contains(tag) {
      return .accent
    }
    return .clear
  }

  func tagsBackgroundColor(_ tags: [String]) -> Color {
    guard let ftags = filter.tags else {
      return .accent
    }
    if ftags.contains(where: { tag in tags.contains(tag) }) {
      return .clear
    }
    return .accent
  }

  func tagsTextColor(_ tags: [String]) -> Color {
    guard let ftags = filter.tags else {
      return .white
    }
    if ftags.contains(where: { tag in tags.contains(tag) }) {
      return .linkText
    }
    return .white
  }

  func appendTag(_ tag: String, tags: [String]) {
    removeTags(tags)
    if var ftags = filter.tags {
      if ftags.contains(tag) {
        return
      } else {
        ftags.append(tag)
      }
      filter.tags = ftags
    } else {
      filter.tags = [tag]
    }
  }

  func removeTags(_ tags: [String]) {
    if var ftags = filter.tags {
      ftags.removeAll(where: tags.contains)
      if ftags.isEmpty {
        filter.tags = nil
      } else {
        filter.tags = ftags
      }
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      CardView {
        HStack {
          Text(title).font(.title3)
          Spacer()
        }
      }
      HFlow {
        Button {
          removeTags(tags)
        } label: {
          BadgeView(background: tagsBackgroundColor(tags), padding: 5) {
            Text("全部")
              .foregroundStyle(tagsTextColor(tags))
          }
        }
        ForEach(tags, id: \.self) { tag in
          Button {
            appendTag(tag, tags: tags)
          } label: {
            BadgeView(background: tagBackgroundColor(tag), padding: 5) {
              Text(tag)
                .foregroundStyle(tagTextColor(tag))
            }
          }.buttonStyle(.scale)
        }
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  return NavigationStack {
    SubjectBrowsingView(type: .anime)
      .modelContainer(container)
  }
}
