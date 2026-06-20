import OSLog
import SwiftUI

struct CalendarSlimView: View {

  private struct CalendarDay: Identifiable {
    let weekday: WeekDay
    let desc: String
    let calendar: CalendarEntryDTO

    var id: WeekDay {
      weekday
    }

    var count: Int {
      calendar.items.count
    }

    var watchers: Int {
      calendar.items.reduce(0) { $0 + $1.watchers }
    }
  }

  @Environment(\.scenePhase) private var scenePhase

  @State private var currentDate = Calendar.current.startOfDay(for: Date())
  @State private var refreshed: Bool = false
  @State private var calendars: [CalendarEntryDTO] = []
  @State private var collectionTypes: [Int: CollectionType] = [:]

  private var dates: [CalendarDay] {
    let today = currentDate
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today

    let todayCalendar =
      calendars.first { $0.weekday == WeekDay(date: today).rawValue }
      ?? CalendarEntryDTO(weekday: WeekDay(date: today).rawValue, items: [])
    let tomorrowCalendar =
      calendars.first { $0.weekday == WeekDay(date: tomorrow).rawValue }
      ?? CalendarEntryDTO(weekday: WeekDay(date: tomorrow).rawValue, items: [])

    let result = [
      CalendarDay(weekday: WeekDay(date: today), desc: "今天", calendar: todayCalendar),
      CalendarDay(weekday: WeekDay(date: tomorrow), desc: "明天", calendar: tomorrowCalendar),
    ]
    return result
  }

  private static func subjectIds(in calendars: [CalendarEntryDTO]) -> [Int] {
    SubjectCollectionTypeResolver.sortedUniqueSubjectIds(
      calendars.flatMap { $0.items.map(\.subject.id) }
    )
  }

  func updateCurrentDate() {
    let today = Calendar.current.startOfDay(for: Date())
    if currentDate != today {
      withAnimation(.default) {
        currentDate = today
      }
    }
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
    VStack {
      if calendars.isEmpty {
        ProgressView().task {
          await loadCachedCalendar()
          await refreshCalendar()
        }
      } else {
        VStack(alignment: .leading, spacing: 8) {
          HStack(alignment: .bottom) {
            Text("每日放送: \(currentDate.formatted(date: .long, time: .omitted))")
            Spacer()
            NavigationLink(value: NavDestination.calendar) {
              Text("更多 »").font(.caption)
            }.buttonStyle(.navigation)
          }
          ForEach(dates) { item in
            VStack(alignment: .leading, spacing: 6) {
              HStack(spacing: 4) {
                Text(item.desc)
                Text("·")
                Text(item.weekday.cn)
                if item.count > 0 {
                  Text("·")
                  Text("\(item.count)部")
                  Text("·")
                  Text("\(item.watchers)人收看")
                }
              }
              .font(.caption)
              .foregroundStyle(.white)
              .padding(.horizontal, 8)
              .padding(.vertical, 3)
              .background(item.weekday.color)
              .cornerRadius(5)
              CalendarWeekdaySlimView(
                calendar: item.calendar,
                collectionTypes: collectionTypes,
                reloadCollectionType: reloadCollectionType
              )
            }
          }
          Divider()
        }
      }
    }
    .padding(.horizontal, 8)
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

struct CalendarWeekdaySlimView: View {
  let calendar: CalendarEntryDTO
  let collectionTypes: [Int: CollectionType]
  let reloadCollectionType: (Int) async -> Void

  @AppStorage("subjectImageQuality") var subjectImageQuality: ImageQuality = .high
  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  static let cardWidth: CGFloat = 110
  static let cardHeight: CGFloat = 110 / 0.707

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(spacing: 8) {
        ForEach(calendar.items) { item in
          ImageView(img: item.subject.images?.resize(subjectImageQuality.mediumSize))
            .imageStyle(width: Self.cardWidth, height: Self.cardHeight)
            .imageType(.subject)
            .imageCaption {
              HStack {
                VStack(alignment: .leading, spacing: 2) {
                  if item.watchers > 10 {
                    Text("\(item.watchers)人追番")
                      .font(.caption2)
                  }
                  Text(item.subject.title(with: titlePreference))
                    .lineLimit(1)
                    .font(.caption)
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
      }.scrollTargetLayout()
    }
    .scrollClipDisabled()
    .scrollTargetBehavior(.viewAligned)
  }
}
