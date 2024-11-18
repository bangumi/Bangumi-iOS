//
//  ContentView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/19.
//

import OSLog
import SwiftData
import SwiftUI

struct ContentView: View {
  @State var notifier = Notifier.shared

  func refreshProfile() async {
    var tries = 0
    while true {
      if tries > 3 {
        break
      }
      tries += 1
      do {
        Notifier.shared.notify(message: "正在获取当前用户信息")
        _ = try await Chii.shared.getProfile()
        await Chii.shared.setAuthStatus(true)
        return
      } catch ChiiError.requireLogin {
        Notifier.shared.notify(message: "请登录")
        await Chii.shared.setAuthStatus(false)
        return
      } catch {
        Notifier.shared.notify(message: "获取当前用户信息失败，重试 \(tries)/3")
        Logger.api.warning("refresh profile failed: \(error)")
      }
      sleep(1)
    }
    Notifier.shared.alert(message: "无法获取当前用户信息，请重新登录")
    await Chii.shared.setAuthStatus(false)
  }

  var body: some View {
    ZStack {
      if UIDevice.current.userInterfaceIdiom == .phone {
        PhoneView()
      } else {
        PadView()
      }
      VStack(alignment: .center) {
        Spacer()
        ForEach($notifier.notifications, id: \.self) { $notification in
          Text(notification)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .foregroundStyle(.white)
            .background(.accent.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
      }
      .animation(.default, value: notifier.notifications)
      .padding(.horizontal, 8)
      .padding(.bottom, 64)
    }
    .alert("ERROR", isPresented: $notifier.hasAlert) {
      Button("OK") {
        Notifier.shared.vanishError()
      }
    } message: {
      if let error = notifier.currentError {
        Text("\(error)")
      } else {
        Text("Unknown Error")
      }
    }
    .task {
      await refreshProfile()
    }
  }
}
