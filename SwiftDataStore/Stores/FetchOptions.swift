//
//  FetchOptions.swift
//  SwiftDataStore
//
//  Created by 16Root24 on 23/09/2025.
//

import Foundation
import SwiftData

/// Enum to define the fetch options
enum FetchOptions {
    /// Fetch all items
    case all
    /// Fetch items with pagination
    case paging(offset: Int, limit: Int)
}
