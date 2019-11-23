//
//  AppState.swift
//  APNsClient
//
//  Created by muukii on 2019/11/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import VergeStore

struct AppState: StateType {
  
  var count: Int = 0
  
  var sessions: [SessionState.ID : SessionState] = [:]
}

struct SessionState: Identifiable {
  
  let id = UUID().uuidString
    
  var count: Int = 0

}

final class Store: VergeDefaultStore<AppState> {
  init() {
    super.init(initialState: .init(), logger: DefaultLogger.shared)
  }
}
