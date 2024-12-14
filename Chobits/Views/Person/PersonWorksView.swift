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
    VStack(spacing: 2) {
      HStack(alignment: .bottom) {
        Text("最近参与")
          .foregroundStyle(relations.count > 0 ? .primary : .secondary)
          .font(.title3)
          .onAppear(perform: load)
        if loading {
          ProgressView()
        }
        Spacer()
        if relations.count > 0 {
          NavigationLink(value: NavDestination.personWorkList(personId)) {
            Text("更多作品 »").font(.caption)
          }.buttonStyle(.navLink)
        }
      }
      Divider()
    }.padding(.top, 5)
    VStack {
      ForEach(relations) { item in
        CardView {
          HStack(alignment: .top) {
            NavigationLink(value: NavDestination.subject(item.subject.id)) {
              ImageView(img: item.subject.images?.common, width: 60, height: 60, type: .subject)
            }
            VStack(alignment: .leading) {
              VStack(alignment: .leading) {
                NavigationLink(value: NavDestination.subject(item.subject.id)) {
                  Text(item.subject.name)
                    .font(.callout)
                    .lineLimit(1)
                }
                if item.subject.nameCN.isEmpty {
                  Label(item.subject.type.description, systemImage: item.subject.type.icon)
                    .lineLimit(1)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                } else {
                  Label(item.subject.nameCN, systemImage: item.subject.type.icon)
                    .lineLimit(1)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                Text(item.subject.info)
                  .font(.caption)
                  .lineLimit(1)
                  .foregroundStyle(.secondary)
                Divider()
              }.frame(height: 60)
              HFlow {
                ForEach(item.positions) { position in
                  HStack {
                    BorderView {
                      Text(position.type.cn).font(.caption)
                    }
                  }
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
                }
              }
            }
            Spacer()
          }.buttonStyle(.navLink)
        }
      }
    }
    .padding(.bottom, 8)
    .animation(.default, value: relations)
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
