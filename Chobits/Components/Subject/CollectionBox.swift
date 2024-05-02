//
//  CollectionBox.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/2.
//

import SwiftUI

struct CollectionBox: View {
  var subject: Subject
  var collection: UserSubjectCollection?

    var body: some View {
        Text("Hello, World!")
    }
}

#Preview {
  CollectionBox(subject: .previewAnime,collection: .previewAnime)
}
