//
//  Collection.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/28.
//

import SwiftUI

struct SubjectCollectionView: View {
  var subject: Subject

  var body: some View {
    VStack(alignment: .leading) {
      Text("收藏").font(.headline)
    }.padding(.vertical, 10)
  }
}
