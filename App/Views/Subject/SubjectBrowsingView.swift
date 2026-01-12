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
      await db.commit()
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
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
      ToolbarItem(placement: .topBarTrailing) {
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

  func yearTextColor(_ year: Int?) -> Color {
    if filter.year == year {
      return .white
    }
    return .linkText
  }

  func yearBackgroundColor(_ year: Int?) -> Color {
    if filter.year == year {
      return .accent
    }
    return .clear
  }

  func monthTextColor(_ month: Int?) -> Color {
    if filter.month == month {
      return .white
    }
    return .linkText
  }

  func monthBackgroundColor(_ month: Int?) -> Color {
    if filter.month == month {
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
              BadgeView(background: yearBackgroundColor(nil), padding: 4) {
                HStack {
                  Spacer()
                  Text("不限年份")
                    .foregroundStyle(yearTextColor(nil))
                  Spacer()
                }
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
                BadgeView(background: .clear, padding: 4) {
                  Text("来年们").foregroundStyle(.linkText)
                }
              }.buttonStyle(.scale)
              ForEach(years, id: \.self) { year in
                Button {
                  filter.year = year
                } label: {
                  BadgeView(background: yearBackgroundColor(year), padding: 4) {
                    Text("\(String(year))年")
                      .foregroundStyle(yearTextColor(year))
                  }
                }.buttonStyle(.scale)
              }
              Button {
                updateYears(modifier: -10)
              } label: {
                BadgeView(background: .clear, padding: 4) {
                  Text("往年们").foregroundStyle(.linkText)
                }
              }.buttonStyle(.scale)
            }.animation(.default, value: years)
            if filter.year != nil {
              Button {
                filter.month = nil
              } label: {
                BadgeView(background: monthBackgroundColor(nil), padding: 4) {
                  HStack {
                    Spacer()
                    Text("不限月份")
                      .foregroundStyle(monthTextColor(nil))
                    Spacer()
                  }
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
                    BadgeView(background: monthBackgroundColor(month), padding: 4) {
                      Text("\(month)月")
                        .foregroundStyle(monthTextColor(month))
                    }
                  }.buttonStyle(.scale)
                }
              }
            }
          }.monospacedDigit()

        }.padding()
      }
      .animation(.default, value: filter)
      .navigationTitle("筛选")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
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

  @State private var tagTextColors: [String: Color] = [:]
  @State private var tagBackgroundColors: [String: Color] = [:]
  @State private var allTagsBackgroundColor: Color = .accent
  @State private var allTagsTextColor: Color = .white

  @State private var lastFilterTags: [String]? = nil

  private func updateColors() {
    if lastFilterTags == filter.tags { return }

    lastFilterTags = filter.tags

    if let ftags = filter.tags {
      allTagsBackgroundColor = ftags.contains(where: { tags.contains($0) }) ? .clear : .accent
      allTagsTextColor = ftags.contains(where: { tags.contains($0) }) ? .linkText : .white
    } else {
      allTagsBackgroundColor = .accent
      allTagsTextColor = .white
    }

    for tag in tags {
      if let ftags = filter.tags {
        tagTextColors[tag] = ftags.contains(tag) ? .white : .linkText
        tagBackgroundColors[tag] = ftags.contains(tag) ? .accent : .clear
      } else {
        tagTextColors[tag] = .linkText
        tagBackgroundColors[tag] = .clear
      }
    }
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
          BadgeView(background: allTagsBackgroundColor, padding: 5) {
            Text("全部")
              .foregroundStyle(allTagsTextColor)
          }
        }
        ForEach(tags, id: \.self) { tag in
          Button {
            appendTag(tag, tags: tags)
          } label: {
            BadgeView(background: tagBackgroundColors[tag, default: .clear], padding: 5) {
              Text(tag)
                .foregroundStyle(tagTextColors[tag, default: .linkText])
            }
          }.buttonStyle(.scale)
        }
      }
    }
    .onAppear {
      lastFilterTags = nil
      updateColors()
    }
    .onChange(of: filter.tags) { _, _ in
      updateColors()
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
