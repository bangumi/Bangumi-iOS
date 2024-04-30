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

  @EnvironmentObject var chiiClient: ChiiClient
  @EnvironmentObject var errorHandling: ErrorHandling

  @State private var subject: Subject? = nil
  @State private var summaryCollapsed = true

  func fetchSubject() {
    Task.detached {
      do {
        let subject = try await chiiClient.getSubject(sid: sid)
        await MainActor.run {
          withAnimation {
            self.subject = subject
          }
        }
      } catch {
        await errorHandling.handle(message: "\(error)")
      }
    }
  }

  var body: some View {
    if let subject = subject {
      ScrollView {
        LazyVStack(alignment: .leading) {
          SubjectHeaderView(subject: subject)
          if chiiClient.isAuthenticated {
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
      Image(systemName: "waveform")
        .resizable()
        .scaledToFit()
        .frame(width: 80, height: 80)
        .symbolEffect(.variableColor.iterative.dimInactiveLayers)
        .onAppear(perform: fetchSubject)
    }
  }
}

#Preview {
  SubjectView(sid: 1)
    .environmentObject(ErrorHandling())
    .environmentObject(ChiiClient(mock: true))
}
