import OSLog
import SwiftData
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

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  @State private var refreshed: Bool = false

  @Query(sort: \BangumiCalendar.weekday)
  private var calendars: [BangumiCalendar]

  var today: Date {
    Date()
  }

  var sortedCalendars: [BangumiCalendar] {
    let weekday = WeekDay(date: today)
    return calendars.sorted { (cal1: BangumiCalendar, cal2: BangumiCalendar) -> Bool in
      if cal1.weekday >= weekday.rawValue && cal2.weekday < weekday.rawValue {
        return true
      } else if cal1.weekday < weekday.rawValue && cal2.weekday >= weekday.rawValue {
        return false
      } else {
        return cal1.weekday < cal2.weekday
      }
    }
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
          Text("每日放送")
            .font(.title)
            .padding(.top, 10)
          VStack {
            Text("\(today.formatted(date: .complete, time: .omitted))")
            Text("本季度共 \(total) 部番组，今日上映 \(todayTotal) 部。")
            Text("共 \(todayWatchers) 人收看今日番组。")
          }
          .font(.footnote)
          .foregroundStyle(.secondary)
        }.padding(.horizontal, 8)
        LazyVStack {
          ForEach(sortedCalendars) { calendar in
            CalendarWeekdayView(calendar: calendar)
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
}

struct CalendarWeekdayView: View {
  @Bindable var calendar: BangumiCalendar

  @AppStorage("titlePreference") var titlePreference: TitlePreference = .original

  var weekday: WeekDay {
    WeekDay(calendar.weekday)
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
              .imageNavLink(item.subject.link)
              .subjectPreview(item.subject)
          }
        }
      }
    }
  }
}
