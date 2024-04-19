//
//  Item.swift
//  Bangumi
//
//  Created by Chuan Chuan on 2024/4/19.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date

    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
