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
      withAnimation(.default) {
        calendars = fetchedCalendars
      }
    } catch {
      Logger.app.error("Failed to load cached calendar: \(error)")
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
              CalendarWeekdaySlimView(calendar: item.calendar)
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
  }
}

struct CalendarWeekdaySlimView: View {
  let calendar: CalendarEntryDTO

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
            .imageNavLink(item.subject.link)
            .subjectPreview(item.subject)
        }
      }.scrollTargetLayout()
    }
    .scrollClipDisabled()
    .scrollTargetBehavior(.viewAligned)
  }
}
