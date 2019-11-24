//
//  AppState.swift
//  APNsClient
//
//  Created by muukii on 2019/11/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import VergeStore

public struct AppState: StateType {
  
  public var count: Int = 0
  
  public var sessions: [SessionState.ID : SessionState] = [:]
}

public struct SessionState: Identifiable {
  
  public let id = UUID().uuidString
  
  public var p8FileURL: URL?
      
  public var count: Int = 0

  public var _ui: Any? = nil
}

public final class Store: VergeDefaultStore<AppState> {
  init() {
    super.init(initialState: .init(), logger: DefaultLogger.shared)
  }
}
