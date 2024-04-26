//
//  CalendarView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/26.
//

import SwiftData
import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var chiiClient: ChiiClient
    @EnvironmentObject var errorHandling: ErrorHandling
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \BangumiCalendar.id) private var calendars: [BangumiCalendar]

    var sortedCalendars: [BangumiCalendar] {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else {
            errorHandling.handle(message: "Could not get yesterday")
            return calendars
        }
        let weekday = calendar.component(.weekday, from: yesterday)
        return calendars.sorted { (cal1: BangumiCalendar, cal2: BangumiCalendar) -> Bool in
            if cal1.id >= weekday && cal2.id < weekday {
                return true
            } else if cal1.id < weekday && cal2.id >= weekday {
                return false
            } else {
                return cal1.id < cal2.id
            }
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(sortedCalendars) { calendar in
                    CalendarWeekdayView(calendar: calendar).padding(.vertical, 10)
                }
            }
        }.refreshable {
            Task {
                do {
                    try await chiiClient.updateCalendar()
                } catch {
                    errorHandling.handle(message: "\(error)")
                }
            }
        }
    }
}

struct CalendarWeekdayView: View {
    let calendar: BangumiCalendar

    func imageURL(url: String) -> URL? {
        var components = URLComponents(string: url)
        components?.scheme = "https"
        return components?.url
    }

    var body: some View {
        VStack {
            Text(calendar.weekday.cn).font(.title3)
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ]) {
                ForEach(calendar.items) { subject in
                    VStack {
                        if let images = subject.images {
                            let iconURL = imageURL(url: images.common)
                            CachedAsyncImage(url: iconURL) { image in
                                image.resizable().scaledToFill().frame(width: 80, height: 80).clipped()
                            } placeholder: {
                                Rectangle().fill(.accent.opacity(0.1)).frame(width: 80, height: 80)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Image(systemName: "photo").frame(width: 80, height: 80)
                        }
                        Text(subject.name).font(.caption).multilineTextAlignment(.leading).lineLimit(1)
                    }
                }
            }
        }
    }
}
