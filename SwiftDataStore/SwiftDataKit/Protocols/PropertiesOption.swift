//
//  PropertiesOption.swift
//  SwiftDataStore
//
//  Created by Abdullah Alhaider on 23/09/2025.
//

import Foundation
import SwiftData

/// Enum to define the properties to fetch, choseing custom properties is better for performance
public enum PropertiesOption<Model: PersistentModel> {
    /// Fetch all properties
    case all
    /// Fetch custom properties
    case custom([PartialKeyPath<Model>])
}
