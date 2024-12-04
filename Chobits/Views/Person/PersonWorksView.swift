//
//  PersonWorksView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/9.
//

import Flow
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
        let resp = try await Chii.shared.getPersonWorks(personId, limit: 5)
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
    VStack {
      ForEach(relations) { item in
        CardView {
          NavigationLink(value: NavDestination.subject(subjectId: item.subject.id)) {
            HStack {
              ImageView(img: item.subject.images?.common, width: 64, height: 64, type: .subject)
              VStack(alignment: .leading) {
                Text(item.subject.name)
                  .font(.callout)
                  .foregroundStyle(.linkText)
                  .lineLimit(1)
                Text(item.subject.nameCN)
                  .font(.footnote)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
                HStack {
                  Image(systemName: item.subject.type.icon)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                  HFlow {
                    ForEach(item.positions) { position in
                      HStack {
                        BorderView {
                          Text(position.type.cn).font(.caption)
                        }
                        Text(position.summary).font(.footnote)
                      }
                      .foregroundStyle(.secondary)
                      .lineLimit(1)
                    }
                  }
                }
              }.padding(.leading, 4)
              Spacer()
            }
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
