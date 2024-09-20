//
//  DiscoverView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/19.
//

import OSLog
import SwiftData
import SwiftUI

struct ChiiDiscoverView: View {
  @Environment(Notifier.self) private var notifier
  @Environment(ChiiClient.self) private var chii
  @Environment(\.modelContext) var modelContext

  var body: some View {
    CalendarView()
      .onOpenURL(perform: { url in
        // TODO: handle urls
        print(url)
      })
  }
}
