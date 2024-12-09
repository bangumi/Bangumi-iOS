//
//  PersonInfoboxView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/9.
//

import Flow
import SwiftData
import SwiftUI

struct PersonInfoboxView: View {
  @ObservableModel var person: Person

  var body: some View {
    ScrollView {
      InfoboxView(infobox: person.infobox)
        .navigationTitle("人物信息")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .automatic) {
            Image(systemName: "info.circle").foregroundStyle(.secondary)
          }
        }
    }
  }
}

#Preview {
  let container = mockContainer()

  let person = Person.preview
  container.mainContext.insert(person)

  return PersonInfoboxView(person: person)
    .modelContainer(container)
}
