import Flow
import OSLog
import SwiftData
import SwiftUI

struct CalendarSlimView: View {

  @State private var refreshed: Bool = false

  @Query(sort: \BangumiCalendar.weekday)
  private var calendars: [BangumiCalendar]

  var today: BangumiCalendar? {
    let weekday = getWeekday(Date())
    return calendars.first { $0.weekday == weekday }
  }

  var todayDesc: String {
    let weekday = getWeekday(Date())
    return Calendar(identifier: .iso8601).weekdaySymbols[weekday]
  }

  var tomorrow: BangumiCalendar? {
    let weekday = getWeekday(Date().addingTimeInterval(86400))
    return calendars.first { $0.weekday == weekday }
  }

  var tomorrowDesc: String {
    let weekday = getWeekday(Date().addingTimeInterval(86400))
    return Calendar(identifier: .iso8601).weekdaySymbols[weekday]
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
    if calendars.isEmpty {
      ProgressView().task {
        await refreshCalendar()
      }
    } else {
      ScrollView {
        VStack {
          HStack {
            Text("每日放送: \(Date().formatted(date: .long, time: .omitted))")
              .font(.title3)
            Spacer()
            NavigationLink(value: NavDestination.calendar) {
              Text("更多 »").font(.caption)
            }.buttonStyle(.navLink)
          }
          HStack(spacing: 0) {
            VStack {
              Text("今天")
              Text(todayDesc)
              Spacer()
            }
            .padding(5)
            .background(Color(hex: 0x339900))
            CalendarWeekdaySlimView()
              .environment(today)
          }
          HStack(spacing: 0) {
            VStack {
              Text("明天")
              Text(tomorrowDesc)
              Spacer()
            }
            .padding(5)
            .background(Color(hex: 0x0085C8))
            CalendarWeekdaySlimView()
              .environment(tomorrow)
          }
        }
      }
    }
  }
}

struct CalendarWeekdaySlimView: View {
  @Environment(BangumiCalendar.self) var calendar

  var body: some View {
    HFlow(spacing: 0) {
      ForEach(calendar.items, id: \.subject) { item in
        ImageView(img: item.subject.images?.small)
          .imageStyle(width: 40, height: 40, cornerRadius: 0)
          .imageType(.subject)
          .imageLink(item.subject.link)
      }
    }
  }
}
