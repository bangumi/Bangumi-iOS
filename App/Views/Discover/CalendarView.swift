import OSLog
import SwiftUI

enum WeekDay: Int, CaseIterable {
  case mon = 1
  case tue = 2
  case wed = 3
  case thu = 4
  case fri = 5
  case sat = 6
  case sun = 7

  init(_ weekday: Int) {
    let value = [0, 7, 1, 2, 3, 4, 5, 6][weekday]
    let tmp = Self(rawValue: value)
    if let out = tmp {
      self = out
    } else {
      self = Self.mon
    }
  }

  init(date: Date) {
    let value = [0, 7, 1, 2, 3, 4, 5, 6][Calendar.current.component(.weekday, from: date)]
    let tmp = Self(rawValue: value)
    if let out = tmp {
      self = out
    } else {
      self = Self.mon
    }
  }

  var color: Color {
    switch self {
    case .sun:
      Color(hex: 0xFB1F19)
    case .mon:
      Color(hex: 0xFB5E21)
    case .tue:
      Color(hex: 0xFCC12C)
    case .wed:
      Color(hex: 0xA9D939)
    case .thu:
      Color(hex: 0x51B235)
    case .fri:
      Color(hex: 0x1579BE)
    case .sat:
      Color(hex: 0x0F4B97)
    }
  }

  var short: String {
    Calendar(identifier: .iso8601).shortWeekdaySymbols[rawValue % 7]
  }

  var desc: String {
    Calendar(identifier: .iso8601).weekdaySymbols[rawValue % 7]
  }

  var cn: String {
    Calendar.current.weekdaySymbols[rawValue % 7]
  }
}

struct CalendarView: View {

  @Environment(\.scenePhase) private var scenePhase

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @State private var currentDate = Calendar.current.startOfDay(for: Date())
  @State private var refreshed: Bool = false
  @State private var calendars: [CalendarEntryDTO] = []
  @State private var collectionTypes: [Int: CollectionType] = [:]

  var sortedCalendars: [CalendarEntryDTO] {
    let todayWeekday = WeekDay(date: currentDate).rawValue
    let sorted = calendars.sorted { $0.weekday < $1.weekday }
    guard let pivot = sorted.firstIndex(where: { $0.weekday >= todayWeekday }) else {
      return sorted
    }
    return Array(sorted[pivot...] + sorted[..<pivot])
  }

  var total: Int {
    calendars.reduce(0) { $0 + $1.items.count }
  }

  var todayTotal: Int {
    sortedCalendars.first?.items.count ?? 0
  }

  var todayWatchers: Int {
    sortedCalendars.first?.items.reduce(0) { $0 + $1.watchers } ?? 0
  }

  private static func subjectIds(in calendars: [CalendarEntryDTO]) -> [Int] {
    SubjectCollectionTypeResolver.sortedUniqueSubjectIds(
      calendars.flatMap { $0.items.map(\.subject.id) }
    )
  }

  func loadCachedCalendar() async {
    do {
      let db = try await AppContext.shared.getDB()
      let fetchedCalendars = try await db.fetchCalendarEntries()
      let fetchedCollectionTypes = try await SubjectCollectionTypeResolver.load(
        subjectIds: Self.subjectIds(in: fetchedCalendars)
      )
      withAnimation(.default) {
        calendars = fetchedCalendars
        collectionTypes = fetchedCollectionTypes
      }
    } catch {
      Logger.app.error("Failed to load cached calendar: \(error)")
    }
  }

  private func loadCollectionTypes(for subjectIds: [Int], replacing: Bool = false) async {
    let subjectIds = SubjectCollectionTypeResolver.sortedUniqueSubjectIds(subjectIds)
    guard !subjectIds.isEmpty else {
      if replacing {
        withAnimation(.default) {
          collectionTypes = [:]
        }
      }
      return
    }
    do {
      let fetchedCollectionTypes = try await SubjectCollectionTypeResolver.load(subjectIds: subjectIds)
      withAnimation(.default) {
        if replacing {
          collectionTypes = fetchedCollectionTypes
        } else {
          for subjectId in subjectIds {
            collectionTypes[subjectId] = fetchedCollectionTypes[subjectId] ?? CollectionType.none
          }
        }
      }
    } catch {
      Logger.app.error("Failed to load calendar collection types: \(error)")
    }
  }

  private func reloadCollectionType(subjectId: Int) async {
    await loadCollectionTypes(for: [subjectId])
  }

  private func handleSubjectInvalidation(_ notification: Notification) {
    guard let subjectId = ProgressSubjectInvalidation.subjectId(from: notification),
      Self.subjectIds(in: calendars).contains(subjectId)
    else { return }
    Task {
      await reloadCollectionType(subjectId: subjectId)
    }
  }

  func updateCurrentDate() {
    let today = Calendar.current.startOfDay(for: Date())
    if currentDate != today {
      withAnimation(.default) {
        currentDate = today
      }
    }
  }

  func refreshCalendar() async {
    if refreshed { return }
    refreshed = true
    do {
      try await DiscoveryRepository.loadCalendar()
      await loadCachedCalendar()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    Group {
      if calendars.isEmpty {
        ProgressView().task {
          await loadCachedCalendar()
          await refreshCalendar()
        }
      } else {
        ScrollView {
          VStack {
            Text("每日放送")
              .font(.title)
              .padding(.top, 10)
            VStack {
              Text("\(currentDate.formatted(date: .complete, time: .omitted))")
              Text("本季度共 \(total) 部番组，今日上映 \(todayTotal) 部。")
              Text("共 \(todayWatchers) 人收看今日番组。")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
          }.padding(.horizontal, 8)
          VStack {
            ForEach(sortedCalendars) { calendar in
              CalendarWeekdayView(
                calendar: calendar,
                collectionTypes: collectionTypes,
                reloadCollectionType: reloadCollectionType
              )
                .padding(.vertical, 10)
            }
          }.padding(.horizontal, 8)
        }
        .navigationTitle("每日放送")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
          refreshed = false
          UIImpactFeedbackGenerator(style: .medium).impactOccurred()
          await refreshCalendar()
        }
      }
    }
    .onAppear {
      updateCurrentDate()
    }
    .onChange(of: scenePhase) {
      if scenePhase == .active {
        updateCurrentDate()
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
      updateCurrentDate()
    }
    .onReceive(
      NotificationCenter.default.publisher(for: ProgressSubjectInvalidation.notificationName),
      perform: handleSubjectInvalidation
    )
  }
}

struct CalendarWeekdayView: View {
  let calendar: CalendarEntryDTO
  let collectionTypes: [Int: CollectionType]
  let reloadCollectionType: (Int) async -> Void

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  var weekday: WeekDay {
    WeekDay(rawValue: calendar.weekday) ?? .mon
  }

  var body: some View {
    VStack {
      HStack {
        Spacer()
        Text(weekday.cn)
        Text(weekday.desc)
        Spacer()
      }
      .padding(.vertical, 5)
      .padding(.horizontal, 10)
      .font(.title3)
      .foregroundStyle(.white)
      .background(weekday.color)
      .cornerRadius(10)
      .shadow(radius: 5)

      LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))]) {
        ForEach(calendar.items) { item in
          VStack {
            ImageView(img: item.subject.images?.resize(.r200))
              .imageStyle(aspectRatio: 0.707)
              .imageType(.subject)
              .imageCaption {
                HStack {
                  VStack(alignment: .leading) {
                    if item.watchers > 10 {
                      Text("\(item.watchers)人追番")
                        .font(.caption)
                    }
                    Text(item.subject.title(with: titlePreference))
                      .lineLimit(1)
                      .font(.footnote)
                      .bold()
                  }
                  Spacer(minLength: 0)
                }.padding(4)
              }
              .imageCollectionStatus(
                ctype: collectionTypes[item.subject.id] ?? CollectionType.none
              )
              .imageNavLink(item.subject.link)
              .subjectPreview(
                item.subject,
                collectionType: collectionTypes[item.subject.id] ?? CollectionType.none
              ) {
                await reloadCollectionType(item.subject.id)
              }
          }
        }
      }
    }
  }
}
