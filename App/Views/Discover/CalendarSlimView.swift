import Flow
import OSLog
import SwiftData
import SwiftUI

struct CalendarSlimView: View {

  @State private var refreshed: Bool = false

  @Query(sort: \BangumiCalendar.weekday)
  private var calendars: [BangumiCalendar]

  var today: BangumiCalendar? {
    let weekday = WeekDay(date: Date())
    return calendars.first { $0.weekday == weekday.rawValue }
  }

  var todayTotal: Int {
    today?.items.count ?? 0
  }

  var todayWatchers: Int {
    today?.items.reduce(0) { $0 + $1.watchers } ?? 0
  }

  var dates: [(weekday: WeekDay, desc: String, date: Date, calendar: BangumiCalendar)] {
    let today = Date()
    let tomorrow = today.addingTimeInterval(86400)

    let todayCalendar =
      calendars.first { $0.weekday == WeekDay(date: today).rawValue }
      ?? BangumiCalendar(weekday: WeekDay(date: today).rawValue, items: [])
    let tomorrowCalendar =
      calendars.first { $0.weekday == WeekDay(date: tomorrow).rawValue }
      ?? BangumiCalendar(weekday: WeekDay(date: tomorrow).rawValue, items: [])

    let result = [
      (weekday: WeekDay(date: today), desc: "今天", date: today, calendar: todayCalendar),
      (weekday: WeekDay(date: tomorrow), desc: "明天", date: tomorrow, calendar: tomorrowCalendar),
    ]
    return result
  }

  func refreshCalendar() async {
    if refreshed { return }
    refreshed = true
    do {
      try await Chii.shared.loadCalendar()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    VStack {
      if calendars.isEmpty {
        ProgressView().task {
          await refreshCalendar()
        }
      } else {
        VStack(alignment: .leading, spacing: 5) {
          HStack(alignment: .bottom) {
            Text("每日放送: \(Date().formatted(date: .long, time: .omitted))")
            Spacer()
            NavigationLink(value: NavDestination.calendar) {
              Text("更多 »").font(.caption)
            }.buttonStyle(.navigation)
          }
          ForEach(dates, id: \.weekday) { item in
            HStack(alignment: .top, spacing: 0) {
              VStack {
                Text(item.desc)
                Text(item.weekday.short)
                Spacer()
              }
              .padding(5)
              .background(item.weekday.color)
              .foregroundStyle(.white)
              CalendarWeekdaySlimView(calendar: item.calendar)
            }
          }
          Text("今日上映 \(todayTotal) 部。共 \(todayWatchers) 人收看今日番组。")
            .font(.footnote)
            .foregroundStyle(.secondary)
          Divider()
        }
      }
    }.padding(.horizontal, 8)
  }
}

struct CalendarWeekdaySlimView: View {
  @Bindable var calendar: BangumiCalendar

  var body: some View {
    HFlow(spacing: 0) {
      ForEach(calendar.items) { item in
        ImageView(img: item.subject.images?.resize(.r100))
          .imageStyle(width: 60, height: 60, cornerRadius: 0)
          .imageType(.subject)
          .imageNavLink(item.subject.link)
          .subjectPreview(item.subject)
      }
    }
  }
}
