//
//  FetchConfigrations.swift
//  SwiftDataStore
//
//  Created by 16Root24 on 30/09/2025.
//

import Foundation
import SwiftData

struct FetchConfigrations<Model: PersistentModel> {
    let sortDescriptors: [SortDescriptor<Model>]
    let predicate: Predicate<Model>?
    let propertiesToFetch: PropertiesOption<Model>
    let relationshipKeyPathsForPrefetching: [PartialKeyPath<Model>]?
    let fetchOptions: FetchOptions
}

extension FetchConfigrations {
    static var `default`: Self {
        Self(
            sortDescriptors: [],
            predicate: nil,
            propertiesToFetch: .all,
            relationshipKeyPathsForPrefetching: nil,
            fetchOptions:  .all
        )
    }
}
