import Flow
import OSLog
import SwiftUI

struct SubjectStaffListView: View {
  let subjectId: Int

  @State private var collectionStatuses: [Int: Bool] = [:]
  @State private var loadedPersonIds: Set<Int> = []

  private func loadCollectionStatuses(personIds: [Int]) async {
    guard !personIds.isEmpty else { return }
    do {
      guard let db = await AppContext.shared.databaseIfAvailable() else { return }
      let statuses = try await db.personCollectionStatuses(personIds: personIds)
      collectionStatuses.merge(statuses) { _, new in new }
    } catch {
      Logger.app.error("Failed to load subject staff collection statuses: \(error)")
    }
  }

  private func handleMonoCollectionInvalidation(_ notification: Notification) {
    guard let personId = MonoCollectionInvalidation.personId(from: notification),
      loadedPersonIds.contains(personId)
    else {
      return
    }
    Task {
      await loadCollectionStatuses(personIds: [personId])
    }
  }

  func load(limit: Int, offset: Int) async -> PagedDTO<SubjectStaffDTO>? {
    do {
      let resp = try await SubjectService.getSubjectStaffPersons(
        subjectId, limit: limit, offset: offset)
      let personIds = resp.data.map { $0.staff.id }
      loadedPersonIds.formUnion(personIds)
      await loadCollectionStatuses(personIds: personIds)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      OffsetPagedView<SubjectStaffDTO, _>(limit: 20, nextPageFunc: load) { item in
        CardView {
          HStack {
            ImageView(img: item.staff.images?.resize(.r200))
              .imageStyle(width: 60, height: 60, alignment: .top)
              .imageType(.person)
              .imageCollectedStatus(collectionStatuses[item.staff.id] ?? false)
              .imageNavLink(item.staff.link)
            VStack(alignment: .leading) {
              Text(item.staff.name.withLink(item.staff.link))
                .font(.callout)
                .lineLimit(1)
              Text(item.staff.nameCN)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
              HFlow {
                ForEach(item.positions) { position in
                  if !position.type.cn.isEmpty {
                    HStack {
                      BorderView {
                        Text(position.type.cn)
                      }
                    }
                  }
                }
              }
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
            }.padding(.leading, 4)
            Spacer()
          }
        }
      }
      .padding(8)
    }
    .buttonStyle(.navigation)
    .onReceive(
      NotificationCenter.default.publisher(for: MonoCollectionInvalidation.notificationName),
      perform: handleMonoCollectionInvalidation
    )
    .onAppear {
      Task {
        await loadCollectionStatuses(personIds: Array(loadedPersonIds))
      }
    }
    .navigationTitle("制作人员")
    .navigationBarTitleDisplayMode(.inline)
  }
}
