//
//  SubjectReviewsRowView.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/12/16.
//

import SwiftUI

struct SubjectReviewItemView: View {
  let item: SubjectReviewDTO

  var body: some View {
    HStack(alignment: .top) {
      NavigationLink(value: NavDestination.user(item.user.username)) {
        ImageView(
          img: item.user.avatar?.large,
          width: 60, height: 60,
          alignment: .top, type: .avatar
        )
      }
      VStack(alignment: .leading) {
        NavigationLink(value: NavDestination.blog(item.entry.id)) {
          HStack(alignment: .bottom) {
            Text(item.entry.title).lineLimit(1)
            Spacer()
            Text("更多 »").font(.caption)
          }
        }
        HStack {
          Text("by").foregroundStyle(.secondary)
          NavigationLink(value: NavDestination.user(item.user.username)) {
            Text(item.user.nickname)
              .lineLimit(1)
          }
          Text(item.entry.createdAt.datetimeDisplay)
            .lineLimit(1)
            .foregroundStyle(.secondary)
          Text("(+\(item.entry.replies))")
            .foregroundStyle(.orange)
        }.font(.footnote)
        Text(item.entry.summary)
          .font(.caption)
          .lineLimit(3)
      }
      Spacer()
    }.buttonStyle(.navLink)
  }
}
