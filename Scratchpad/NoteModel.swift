//
//  Item.swift
//  Scratchpad
//
//  Created by Duncan Crawbuck on 2/19/25.
//

import Foundation
import SwiftData

@Model
final class NoteModel {
    var timestamp: Date = Date()
    var text: String = ""
    
    init(text: String = "") {
        self.text = text
    }
}
