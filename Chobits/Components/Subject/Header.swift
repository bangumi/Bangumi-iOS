//
//  Header.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/28.
//

import SwiftUI

struct SubjectHeaderView: View {
  let subject: Subject

  @State private var coverDetail = false
  @State private var collectionDetail = false

  var body: some View {
    HStack(alignment: .top) {
      ImageView(img: subject.images.common, width: 100, height: 150)
        .onTapGesture {
          coverDetail.toggle()
        }
        .sheet(isPresented: $coverDetail) {
          ImageView(img: subject.images.large, width: 0, height: 0)
            .presentationDragIndicator(.visible)
            .presentationDetents([.fraction(0.8)])
        }
      VStack(alignment: .leading) {
        HStack {
          Text(subject.platform).foregroundStyle(.secondary)
          Label(subject.typeEnum.description, systemImage: subject.typeEnum.icon).foregroundStyle(
            .accent)
          if subject.date.timeIntervalSince1970 > 0 {
            Label(subject.date.formatAirdate, systemImage: "calendar").foregroundStyle(.secondary)
          }
          Spacer()
          if subject.nsfw {
            Label("", systemImage: "18.circle").foregroundStyle(.red)
          }
          if subject.locked {
            Label("", systemImage: "lock").foregroundStyle(.red)
          }
        }.font(.footnote)
        Spacer()
        Text(subject.name)
          .font(.title3.bold())
          .multilineTextAlignment(.leading)
          .lineLimit(2)
        Spacer()
        Text(subject.nameCn)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.leading)
          .lineLimit(2)
        Spacer()
        HStack {
          Label("\(subject.rating.total)", systemImage: "bookmark").foregroundStyle(
            Color("LinkTextColor"))
          Spacer()
          if subject.rating.rank > 0 {
            Label("\(subject.rating.rank)", systemImage: "chart.bar.xaxis").foregroundStyle(.accent)
          }
          if subject.rating.score > 0 {
            Label("\(subject.rating.score.rateDisplay)", systemImage: "star").foregroundStyle(
              .accent)
          }
        }
        .font(.subheadline)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .onTapGesture {
          collectionDetail.toggle()
        }
        .sheet(
          isPresented: $collectionDetail,
          content: {
            SubjectRatingView(subject: subject)
              .presentationDragIndicator(.visible)
              .presentationDetents(.init([.fraction(0.4)]))
          })
      }.padding(.leading, 5)
    }
  }
}

#Preview {
  ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectHeaderView(subject: .previewAnime)
    }
  }.padding()
}
