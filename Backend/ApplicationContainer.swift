//
//  ApplicationContainer.swift
//  APNsClient
//
//  Created by muukii on 2019/11/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import VergeStore

public enum ApplicationContainer {
  public static let store = Store()
  
  public static let dispatcher = ApplicationDispatcher()
    
  public static var activeContexts: [AppContext] = []
  
  public static func makeContext() -> AppContext {
    let id = dispatcher.commit.makeSessionState()
    let context = AppContext(sessionStateID: id)
    activeContexts.append(context)
    return context
  }
}

public final class ApplicationDispatcher: Dispatcher<AppState> {
  
  fileprivate init() {
    super.init(target: ApplicationContainer.store)
  }
   
}

extension Mutations where Base : ApplicationDispatcher {
  
  public func makeSessionState() -> SessionState.ID {
    
    let state = SessionState()
    
    descriptor.commit {
      $0.sessions[state.id] = state
    }
    
    return state.id
    
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
