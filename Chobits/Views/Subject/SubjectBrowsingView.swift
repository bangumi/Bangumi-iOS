//
//  SubjectBrowsingView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/6/3.
//

import SwiftData
import SwiftUI

struct SubjectBrowsingView: View {
  let subjectType: SubjectType
  let categories: [SubjectCategory]

  @Environment(Notifier.self) private var notifier
  @Environment(\.modelContext) var modelContext

  @State private var filterExpand: String = ""
  @State private var filter: SubjectsBrowseFilter = SubjectsBrowseFilter()
  @State var years: [Int32]

  @State private var fetching: Bool = false
  @State private var offset: Int = 0
  @State private var total: Int = 0
  @State private var exhausted: Bool = false
  @State private var subjects: [EnumerateItem<(UInt)>] = []

  init(subjectType: SubjectType) {
    self.subjectType = subjectType
    switch subjectType {
    case .anime:
      self.categories = SubjectCategoryAnime.categories()
    case .book:
      self.categories = SubjectCategoryBook.categories()
    case .game:
      self.categories = SubjectCategoryGame.categories()
    case .real:
      self.categories = SubjectCategoryReal.categories()
    default:
      self.categories = []
    }
    let date = Date()
    let calendar = Calendar.current
    let currentYear = calendar.component(.year, from: date)
    var years: [Int32] = []
    for idx in 0...9 {
      years.append(Int32(currentYear - idx))
    }
    self.years = years
  }

  func updateYears(modifier: Int32) {
    years = years.map { $0 + modifier }
  }

  func browse(limit: Int = 20) async -> [EnumerateItem<(UInt)>] {
    if fetching {
      return []
    }
    fetching = true
    do {
      guard let db = await Chii.shared.db else {
        throw ChiiError.uninitialized
      }
      let resp = try await Chii.shared.getSubjects(
        type: subjectType, filter: filter.dto(), limit: limit, offset: offset)
      total = resp.total
      if offset >= resp.total {
        exhausted = true
      }
      var result: [EnumerateItem<(UInt)>] = []
      for item in resp.data.enumerated() {
        try await db.saveSubject(item.element)
        result.append(EnumerateItem(idx: item.offset + offset, inner: (item.element.id)))
      }
      try await db.commit()
      if result.count < limit {
        exhausted = true
      }
      offset += limit
      fetching = false
      return result
    } catch {
      notifier.alert(error: error)
    }
    fetching = false
    return []
  }

  func newBrowse() async {
    offset = 0
    exhausted = false
    subjects.removeAll()
    let subjects = await browse()
    self.subjects.append(contentsOf: subjects)
    fetching = false
  }

  func browseNextPage(idx: Int) async {
    if exhausted {
      return
    }
    if idx != offset - 5 {
      return
    }
    let subjects = await browse()
    self.subjects.append(contentsOf: subjects)
  }

  var body: some View {
    ScrollView {
      LazyVStack {
        HStack {
          Label("筛选", systemImage: "square.and.pencil")
            .task {
              if subjects.count == 0, !exhausted {
                await newBrowse()
              }
            }
          // cat
          if categories.count > 0 {
            Button {
              if filterExpand == "cat" {
                filterExpand = ""
              } else {
                filterExpand = "cat"
              }
            } label: {
              if let cat = filter.cat {
                Text(cat.name).foregroundStyle(.accent)
              } else {
                Text("类型").foregroundStyle(.linkText)
              }
              Image(systemName: filterExpand == "cat" ? "chevron.up" : "chevron.down")
                .foregroundStyle(filter.cat == nil ? .linkText : .accent).padding(
                  .horizontal, -5)
            }.padding(.horizontal, 5)
          }

          // series
          if subjectType == .book {
            Button {
              if filterExpand == "series" {
                filterExpand = ""
              } else {
                filterExpand = "series"
              }
            } label: {
              if let series = filter.series {
                Text(series ? "系列" : "单行本").foregroundStyle(.accent)
              } else {
                Text("系列").foregroundStyle(.linkText)
              }
              Image(systemName: filterExpand == "series" ? "chevron.up" : "chevron.down")
                .foregroundStyle(filter.series == nil ? .linkText : .accent).padding(
                  .horizontal, -5)
            }.padding(.horizontal, 5)
          }

          // platform
          if subjectType == .game {
            Button {
              if filterExpand == "platform" {
                filterExpand = ""
              } else {
                filterExpand = "platform"
              }
            } label: {
              if filter.platform.isEmpty {
                Text("平台").foregroundStyle(.linkText)
              } else {
                Text(filter.platform).foregroundStyle(.accent)
              }
              Image(systemName: filterExpand == "platform" ? "chevron.up" : "chevron.down")
                .foregroundStyle(filter.platform.isEmpty ? .linkText : .accent)
                .padding(.horizontal, -5)
            }.padding(.horizontal, 5)
          }

          // date
          Button {
            if filterExpand == "year" || filterExpand == "month" {
              filterExpand = ""
            } else {
              filterExpand = "year"
            }
          } label: {
            if filter.year == 0 {
              Text("日期").foregroundStyle(.linkText)
            } else {
              if filter.month == 0 {
                Text("\(String(filter.year))年").foregroundStyle(.accent)
              } else {
                Text("\(String(filter.year))年\(String(filter.month))月").foregroundStyle(.accent)
              }
            }
            Image(
              systemName: filterExpand == "year" || filterExpand == "month"
                ? "chevron.up" : "chevron.down"
            ).foregroundStyle(filter.year == 0 ? .linkText : .accent).padding(
              .horizontal, -5)
          }.padding(.horizontal, 5)

          Spacer()
        }
        .disabled(fetching)
        .padding(.vertical, 2)

        Section {
          switch filterExpand {
          case "cat":
            Button {
              if filter.cat != nil {
                filter.cat = nil
                filterExpand = ""
                Task {
                  await newBrowse()
                }
              }
            } label: {
              if filter.cat == nil {
                Text("不限").foregroundStyle(.accent)
              } else {
                Text("不限").foregroundStyle(.linkText)
              }
            }
            .buttonStyle(.plain)
            FlowStack(spacing: CGSize(width: 15, height: 10)) {
              ForEach(categories, id: \.id) { category in
                Button {
                  if filter.cat?.id != category.id {
                    filter.cat = category
                    filterExpand = ""
                    Task {
                      await newBrowse()
                    }
                  }
                } label: {
                  if let cat = filter.cat, cat.id == category.id {
                    Text(category.name).foregroundStyle(.accent)
                  } else {
                    Text(category.name).foregroundStyle(.linkText)
                  }
                }
                .buttonStyle(.plain)
              }
            }
          case "series":
            Button {
              if filter.series != nil {
                filter.series = nil
                filterExpand = ""
                Task {
                  await newBrowse()
                }
              }
            } label: {
              if filter.series == nil {
                Text("不限").foregroundStyle(.accent)
              } else {
                Text("不限").foregroundStyle(.linkText)
              }
            }
            .buttonStyle(.plain)
            FlowStack(spacing: CGSize(width: 15, height: 10)) {
              Button {
                if filter.series != true {
                  filter.series = true
                  filterExpand = ""
                  Task {
                    await newBrowse()
                  }
                }
              } label: {
                if let series = filter.series, series {
                  Text("系列").foregroundStyle(.accent)
                } else {
                  Text("系列").foregroundStyle(.linkText)
                }
              }
              .buttonStyle(.plain)
              Button {
                if filter.series != false {
                  filter.series = false
                  filterExpand = ""
                  Task {
                    await newBrowse()
                  }
                }
              } label: {
                if let series = filter.series, !series {
                  Text("单行本").foregroundStyle(.accent)
                } else {
                  Text("单行本").foregroundStyle(.linkText)
                }
              }
              .buttonStyle(.plain)
            }
          case "platform":
            Button {
              if !filter.platform.isEmpty {
                filter.platform = ""
                filterExpand = ""
                Task {
                  await newBrowse()
                }
              }
            } label: {
              if filter.platform.isEmpty {
                Text("不限").foregroundStyle(.accent)
              } else {
                Text("不限").foregroundStyle(.linkText)
              }
            }
            .buttonStyle(.plain)
            FlowStack(spacing: CGSize(width: 15, height: 10)) {
              ForEach(GAME_PLATFORMS, id: \.self) { platform in
                Button {
                  if filter.platform != platform {
                    filter.platform = platform
                    filterExpand = ""
                    Task {
                      await newBrowse()
                    }
                  }
                } label: {
                  if filter.platform == platform {
                    Text(platform).foregroundStyle(.accent)
                  } else {
                    Text(platform).foregroundStyle(.linkText)
                  }
                }
                .buttonStyle(.plain)
              }
            }
          case "year":
            Button {
              filter.year = 0
              filter.month = 0
              filterExpand = ""
              Task {
                await newBrowse()
              }
            } label: {
              if filter.year == 0 {
                Text("不限").foregroundStyle(.accent)
              } else {
                Text("不限").foregroundStyle(.linkText)
              }
            }
            .buttonStyle(.plain)
            .padding(2)
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
              .buttonStyle(.plain)
              .padding(2)
              ForEach(years, id: \.self) { year in
                Button {
                  filter.year = year
                  filterExpand = "month"
                } label: {
                  if filter.year == year {
                    Text("\(String(year))年").foregroundStyle(.accent)
                  } else {
                    Text("\(String(year))年").foregroundStyle(.linkText)
                  }
                }
                .buttonStyle(.plain)
                .padding(2)
              }
              Button {
                updateYears(modifier: -10)
              } label: {
                Text("往年们").foregroundStyle(.linkText)
              }
              .buttonStyle(.plain)
              .padding(2)
            }.animation(.default, value: years)
          case "month":
            Button {
              filter.month = 0
              filterExpand = ""
              Task {
                await newBrowse()
              }
            } label: {
              if filter.month == 0 {
                Text("不限").foregroundStyle(.accent)
              } else {
                Text("不限").foregroundStyle(.linkText)
              }
            }
            .buttonStyle(.plain)
            .padding(2)
            LazyVGrid(columns: [
              GridItem(.flexible()),
              GridItem(.flexible()),
              GridItem(.flexible()),
              GridItem(.flexible()),
            ]) {
              ForEach(1..<13) { month in
                Button {
                  if filter.month != month {
                    filter.month = Int8(month)
                    filterExpand = ""
                    Task {
                      await newBrowse()
                    }
                  }
                } label: {
                  if filter.month == month {
                    Text("\(month)月").foregroundStyle(.accent)
                  } else {
                    Text("\(month)月").foregroundStyle(.linkText)
                  }
                }
                .buttonStyle(.plain)
                .padding(2)
              }
            }
          default:
            EmptyView()
          }
        }

        HStack {
          Image(systemName: "line.3.horizontal.decrease.circle")
          Text("按")
          Button {
            if filterExpand == "sort" {
              filterExpand = ""
            } else {
              filterExpand = "sort"
            }
          } label: {
            switch filter.sort {
            case "rank":
              Label("排名", systemImage: "chart.bar.xaxis")
            case "date":
              Label("日期", systemImage: "calendar")
            default:
              Text("未知")
            }
            Image(systemName: filterExpand == "sort" ? "chevron.up" : "chevron.down").padding(
              .horizontal, -5)
          }.padding(.horizontal, 5)
          Text("排序")
          Spacer()
          if total > 0 {
            Text("共\(total)条")
              .foregroundStyle(.secondary)
          }
        }
        .disabled(fetching)
        .padding(.vertical, 2)

        Section {
          switch filterExpand {
          case "sort":
            FlowStack(spacing: CGSize(width: 15, height: 10)) {
              Button {
                if filter.sort != "rank" {
                  filter.sort = "rank"
                  filterExpand = ""
                  Task {
                    await newBrowse()
                  }
                }
              } label: {
                Label("排名", systemImage: "chart.bar.xaxis")
                  .foregroundStyle(filter.sort == "rank" ? .accent : .linkText)
              }.buttonStyle(.plain)
              Button {
                if filter.sort != "date" {
                  filter.sort = "date"
                  filterExpand = ""
                  Task {
                    await newBrowse()
                  }
                }
              } label: {
                Label("日期", systemImage: "calendar")
                  .foregroundStyle(filter.sort == "date" ? .accent : .linkText)
              }.buttonStyle(.plain)
            }
          default:
            EmptyView()
          }
        }

        Divider()

        ForEach(subjects, id: \.idx) { item in
          NavigationLink(value: NavDestination.subject(subjectId: item.inner)) {
            SubjectLargeRowView(subjectId: item.inner)
              .onAppear {
                Task {
                  await browseNextPage(idx: item.idx)
                }
              }
          }.buttonStyle(.plain)
          Divider()
        }

        if fetching {
          HStack {
            Spacer()
            ProgressView()
            Spacer()
          }
        }
        if exhausted {
          HStack {
            Spacer()
            Text("没有更多了")
              .font(.footnote)
              .foregroundStyle(.secondary)
            Spacer()
          }
        }
      }.padding(.horizontal, 8)
    }
    .navigationTitle("全部\(subjectType.description)")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  let container = mockContainer()

  return NavigationStack {
    SubjectBrowsingView(subjectType: .anime)
      .environment(Notifier())
      .modelContainer(container)
  }
}
