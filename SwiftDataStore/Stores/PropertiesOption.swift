//
//  PropertiesOption.swift
//  SwiftDataStore
//
//  Created by 16Root24 on 23/09/2025.
//

import Foundation

/// Enum to define the properties to fetch, choseing custom properties is better for performance
enum PropertiesOption<Model: Identifiable> {
    /// Fetch all properties
    case all
    /// Fetch custom properties
    case custom([PartialKeyPath<Model>])
}
