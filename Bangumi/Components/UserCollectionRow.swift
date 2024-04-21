//
//  UserCollectionRow.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/21.
//

import SwiftUI

struct UserCollectionRow: View {
    var collection: UserSubjectCollection

    var body: some View {
        Text(collection.subject?.name ?? "")
    }
}

// #Preview {
//    UserCollectionRow(collection: collections[0])
// }
