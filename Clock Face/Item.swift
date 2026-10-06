//
//  Item.swift
//  Clock Face
//
//  Created by Web2 on 06/10/26.
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
