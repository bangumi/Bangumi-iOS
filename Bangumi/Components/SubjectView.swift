//
//  SubjectView.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/27.
//

import SwiftUI

struct SubjectView: View {
  var sid: UInt

  @EnvironmentObject var chiiClient: ChiiClient
  @EnvironmentObject var errorHandling: ErrorHandling
  @Environment(\.modelContext) private var modelContext

  var body: some View {
    Text("Hello, Subject: \(sid)")
  }
}
