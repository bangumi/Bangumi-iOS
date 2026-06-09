import OSLog
import SwiftData
import SwiftUI

struct CalendarSlimView: View {

  @State private var refreshed: Bool = false

  @Query(sort: \BangumiCalendar.weekday)
  private var calendars: [BangumiCalendar]

  var dates: [(weekday: WeekDay, desc: String, date: Date, calendar: BangumiCalendar, count: Int, watchers: Int)] {
    let today = Date()
    let tomorrow = today.addingTimeInterval(86400)

    let todayCalendar =
      calendars.first { $0.weekday == WeekDay(date: today).rawValue }
      ?? BangumiCalendar(weekday: WeekDay(date: today).rawValue, items: [])
    let tomorrowCalendar =
      calendars.first { $0.weekday == WeekDay(date: tomorrow).rawValue }
      ?? BangumiCalendar(weekday: WeekDay(date: tomorrow).rawValue, items: [])

    let result = [
      (weekday: WeekDay(date: today), desc: "今天", date: today,
       calendar: todayCalendar,
       count: todayCalendar.items.count,
       watchers: todayCalendar.items.reduce(0) { $0 + $1.watchers }),
      (weekday: WeekDay(date: tomorrow), desc: "明天", date: tomorrow,
       calendar: tomorrowCalendar,
       count: tomorrowCalendar.items.count,
       watchers: tomorrowCalendar.items.reduce(0) { $0 + $1.watchers }),
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
        VStack(alignment: .leading, spacing: 8) {
          HStack(alignment: .bottom) {
            Text("每日放送: \(Date().formatted(date: .long, time: .omitted))")
            Spacer()
            NavigationLink(value: NavDestination.calendar) {
              Text("更多 »").font(.caption)
            }.buttonStyle(.navigation)
          }
          ForEach(dates, id: \.weekday) { item in
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
    }.padding(.horizontal, 8)
  }
}

struct CalendarWeekdaySlimView: View {
  @Bindable var calendar: BangumiCalendar

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
