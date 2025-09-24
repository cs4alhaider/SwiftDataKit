//
//  Date+RelativeTime.swift
//  SwiftDataStore
//
//  Created by 16Root24 on 23/09/2025.
//

import Foundation

extension Date {
    func relativeTime() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
