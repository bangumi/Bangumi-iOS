//
//  PersonWorksView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/9.
//

import SwiftData
import SwiftUI

struct PersonWorksView: View {
  let personId: Int

  @State private var loaded: Bool = false
  @State private var loading: Bool = false
  @State private var relations: [PersonWorkDTO] = []

  func load() {
    if loading || loaded {
      return
    }
    loading = true
    Task {
      do {
        let resp = try await Chii.shared.getPersonWorks(personId, limit: 10)
        relations.append(contentsOf: resp.data)
      } catch {
        Notifier.shared.alert(error: error)
      }
      loading = false
      loaded = true
    }
  }

  var body: some View {
    Divider()
    HStack {
      Text("最近参与")
        .foregroundStyle(relations.count > 0 ? .primary : .secondary)
        .font(.title3)
        .onAppear(perform: load)
      if loading {
        ProgressView()
      }
      Spacer()
      if relations.count > 0 {
        NavigationLink(value: NavDestination.personWorkList(personId: personId)) {
          Text("更多作品 »").font(.caption).foregroundStyle(.linkText)
        }.buttonStyle(.plain)
      }
    }
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(alignment: .top) {
        ForEach(relations) { item in
          NavigationLink(value: NavDestination.subject(subjectId: item.subject.id)) {
            VStack {
              ImageView(img: item.subject.images?.common, width: 60, height: 80, overlay: .caption) {
                Text(item.position.cn)
                  .foregroundStyle(.white)
                  .lineLimit(1)
              }
              Text(item.subject.name)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
              Spacer()
            }
            .font(.caption)
            .frame(width: 60, height: 145)
          }.buttonStyle(.plain)
        }
      }
    }.animation(.default, value: relations)
  }
}

#Preview {
  let container = mockContainer()
  let person = Person.preview
  container.mainContext.insert(person)

  return NavigationStack {
    ScrollView {
      LazyVStack(alignment: .leading) {
        PersonWorksView(personId: person.personId)
          .modelContainer(container)
      }
    }.padding()
  }
}
