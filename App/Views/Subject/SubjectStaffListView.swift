import Flow
import SwiftUI

struct SubjectStaffListView: View {
  let subjectId: Int

  func load(limit: Int, offset: Int) async -> PagedDTO<SubjectStaffListItemDTO>? {
    do {
      let resp = try await SubjectService.getSubjectStaffPersons(
        subjectId, limit: limit, offset: offset)
      guard let db = await AppContext.shared.databaseIfAvailable() else {
        return PagedDTO(
          data: resp.data.map { SubjectStaffListItemDTO(item: $0, isCollected: false) },
          total: resp.total
        )
      }
      let statuses = try await db.personCollectionStatuses(
        personIds: resp.data.map { $0.staff.id }
      )
      return PagedDTO(
        data: resp.data.map {
          SubjectStaffListItemDTO(
            item: $0,
            isCollected: statuses[$0.staff.id] ?? false
          )
        },
        total: resp.total
      )
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      OffsetPagedView<SubjectStaffListItemDTO, _>(limit: 20, nextPageFunc: load) { item in
        CardView {
          HStack {
            ImageView(img: item.item.staff.images?.resize(.r200))
              .imageStyle(width: 60, height: 60, alignment: .top)
              .imageType(.person)
              .imageCollectedStatus(item.isCollected)
              .imageNavLink(item.item.staff.link)
            VStack(alignment: .leading) {
              Text(item.item.staff.name.withLink(item.item.staff.link))
                .font(.callout)
                .lineLimit(1)
              Text(item.item.staff.nameCN)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
              HFlow {
                ForEach(item.item.positions) { position in
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
    .navigationTitle("制作人员")
    .navigationBarTitleDisplayMode(.inline)
  }
}
