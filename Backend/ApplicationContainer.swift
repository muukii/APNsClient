//
//  ApplicationContainer.swift
//  APNsClient
//
//  Created by muukii on 2019/11/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import Verge

public enum ApplicationContainer {
  public static let store = Store()
  
  public static let dispatcher = ApplicationDispatcher()
    
  public static var activeContexts: [AppContext] = []
  
  public static func makeContext() -> AppContext {
    let id = dispatcher.makeSessionState()
    let context = AppContext(sessionStateID: id)
    activeContexts.append(context)
    return context
  }
}

public final class ApplicationDispatcher: Store.Dispatcher {
  
  fileprivate init() {
    super.init(targetStore: ApplicationContainer.store)
  }
   
  public func makeSessionState() -> SessionState.ID {
    commit {
      let state = SessionState()
      $0.sessions[state.id] = state
      return state.id
    }          
  }
}

public final class AppContext {
  
  public let sessionStateID: String
    
  public let stack: Stack
  
  public init(sessionStateID: String) {
    self.stack = .init(sessionStateID: sessionStateID)
    self.sessionStateID = sessionStateID
  }
}
