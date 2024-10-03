//
//  NotificationView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/4.
//

import SwiftData
import SwiftUI

struct NotificationView: View {
  var body: some View {
    Text("施工中 🚧")
  }
}

#Preview {
  let container = mockContainer()

  return NotificationView()
    .environment(Notifier())
    .modelContainer(container)
}
