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
  @Environment(Notifier.self) private var notifier

  @State private var initialized = false

  func refreshProfile() async {
    var tries = 0
    while true {
      if tries > 3 {
        break
      }
      tries += 1
      do {
        _ = try await Chii.shared.getProfile()
        await Chii.shared.setAuthStatus(true)
        self.initialized = true
        return
      } catch ChiiError.requireLogin {
        await Chii.shared.setAuthStatus(false)
        self.initialized = true
        return
      } catch {
        Logger.api.warning("refresh profile failed: \(error)")
      }
    }
    await Chii.shared.setAuthStatus(false)
    self.initialized = true
  }

  var body: some View {
    if !initialized {
      VStack {
        LoadingView().onAppear {
          Task {
            await refreshProfile()
          }
        }
      }
    } else {
      if UIDevice.current.userInterfaceIdiom == .phone {
        PhoneView()
      } else {
        PadView()
      }
    }
  }
}
