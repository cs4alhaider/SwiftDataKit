//
//  ObservableStoreProtocol.swift
//  SwiftDataStore
//
//  Created by 16Root24 on 30/09/2025.
//

import Foundation

protocol ObservableStoreProtocol: StoreProtocol, Observable {
    
    var items: [Model] { get set }
}
