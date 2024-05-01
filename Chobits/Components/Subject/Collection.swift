//
//  Collection.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import SwiftUI

struct SubjectCollectionView: View {
  var subject: Subject

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) private var modelContext

  @State private var empty: Bool = false
  @State private var collection: UserSubjectCollection?

  func fetchCollection() {
    Task.detached {
      do {
        let resp = try await chii.getCollection(sid: subject.id)
        await MainActor.run {
          self.collection = resp
          self.empty = false
          modelContext.insert(resp)
        }
      } catch ChiiError.notFound(_) {
        await MainActor.run {
          self.empty = true
        }
      } catch {
        await notifier.alert(message: "\(error)")
      }
    }
  }

  var body: some View {
    HStack {
      Text("收藏").font(.headline)
      Spacer()
      if let collection = collection {
        if collection.private {
          Image(systemName: "lock.fill")
            .foregroundStyle(.accent)
        }
        Text(collection.type.message(type: collection.subjectType))
          .foregroundStyle(Color("LinkTextColor"))
          .overlay {
            RoundedRectangle(cornerRadius: 4)
              .stroke(Color("LinkTextColor"), lineWidth: 1)
              .padding(.horizontal, -4)
              .padding(.vertical, -2)
          }
          .padding(5)
      } else {
        if empty {
          Text("未收藏")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .overlay {
              RoundedRectangle(cornerRadius: 4)
                .stroke(.secondary, lineWidth: 1)
                .padding(.horizontal, -4)
                .padding(.vertical, -2)
            }.padding(5)
        } else {
          EmptyView()
        }
      }
    }
    if let collection = collection {
      switch collection.subjectType {
      case .book:
        SubjectCollectionBookView(subject: subject, collection: collection)
      case .anime:
        Text("动画")
      case .music:
        Text("音乐")
      case .game:
        Text("游戏")
      case .real:
        Text("影视")
      default:
        Text("未知")
      }
      // TODO: show
      Text("\(collection.updatedAt)").font(.caption).foregroundStyle(.secondary)
    } else {
      if empty {
        // TODO: show
        EmptyView()
      } else {
        HStack{
          Spacer()
          ProgressView()
          Spacer()
        }
        .onAppear(perform: fetchCollection)
      }
    }
  }
}

struct SubjectCollectionBookView: View {
  var subject: Subject
  var collection: UserSubjectCollection

  @EnvironmentObject var notifier: Notifier
  @EnvironmentObject var chii: ChiiClient
  @Environment(\.modelContext) private var modelContext

  @State private var eps: UInt
  @State private var vols: UInt
  @State private var waiting: Bool = false

  init(subject: Subject, collection: UserSubjectCollection) {
    self.subject = subject
    self.collection = collection
    self.eps = collection.epStatus
    self.vols = collection.volStatus
  }

  var body: some View {
    HStack{
      HStack(alignment: .firstTextBaseline, spacing: 0) {
        TextField("eps", value: $eps, formatter: NumberFormatter())
          .keyboardType(.numberPad)
          .frame(width: 60)
          .multilineTextAlignment(.trailing)
          .fixedSize(horizontal: true, vertical: false)
          .padding(.trailing, 5)
          .background(.secondary.opacity(0.05))
          .cornerRadius(4)
        Text(subject.eps>0 ? "/\(subject.eps) 话" : "/? 话")
          .foregroundColor(.secondary)
      }.monospaced()
      HStack(alignment: .firstTextBaseline, spacing: 0) {
        TextField("vols", value: $vols, formatter: NumberFormatter())
          .keyboardType(.numberPad)
          .frame(width: 60)
          .multilineTextAlignment(.trailing)
          .fixedSize(horizontal: true, vertical: false)
          .padding(.trailing, 5)
          .background(.secondary.opacity(0.05))
          .cornerRadius(4)
        Text(subject.volumes>0 ? "/\(subject.volumes) 卷" : "/? 卷")
          .foregroundColor(.secondary)
      }.monospaced()
      Spacer()
      Button("更新") {
        let argEps:UInt? = eps == collection.epStatus ? nil: eps
        let argVols:UInt? = vols == collection.volStatus ? nil: vols
        self.waiting = true
        Task.detached {
          do {
            let resp = try await chii.updateCollection(sid: subject.id, eps: argEps, vols: argVols)
            await MainActor.run {
              modelContext.insert(resp)
            }
          } catch {
            await notifier.alert(message: "\(error)")
          }
          await MainActor.run {
            self.waiting = false
          }
        }
      }
      .buttonStyle(.borderedProminent)
      .disabled(waiting)
    }
  }
}

#Preview {
  ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectCollectionView(subject: .previewBook)
        .environmentObject(Notifier())
        .environmentObject(ChiiClient(mock: .book))
    }
  }.padding()
}
