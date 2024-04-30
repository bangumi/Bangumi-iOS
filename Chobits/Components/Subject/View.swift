//
//  View.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/27.
//

import SwiftData
import SwiftUI

struct SubjectView: View {
  var sid: UInt

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient

  @State private var subject: Subject? = nil
  @State private var summaryCollapsed = true

  func fetchSubject() {
    Task.detached {
      do {
        let subject = try await chii.getSubject(sid: sid)
        await MainActor.run {
          withAnimation {
            self.subject = subject
          }
        }
      } catch {
        await notifier.alert(message: "\(error)")
      }
    }
  }

  var body: some View {
    if let subject = subject {
      ScrollView {
        LazyVStack(alignment: .leading) {
          SubjectHeaderView(subject: subject)
          if chii.isAuthenticated {
            SubjectCollectionView(subject: subject)
          }
          if !subject.summary.isEmpty {
            SubjectSummaryView(subject: subject)
          }
          SubjectTagView(subject: subject)
          Spacer()
        }
      }
      .padding()
    } else {
      ProgressView()
        .onAppear(perform: fetchSubject)
    }
  }
}

#Preview {
  SubjectView(sid: 1)
    .environmentObject(Notifier())
    .environmentObject(ChiiClient(mock: true))
}
