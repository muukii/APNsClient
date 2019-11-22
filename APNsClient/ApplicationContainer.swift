//
//  ApplicationContainer.swift
//  APNsClient
//
//  Created by muukii on 2019/11/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import VergeStore

enum ApplicationContainer {
  static let store = Store()
  
  static let dispatcher = ApplicationDispatcher()
    
  static var activeContexts: [AppContext] = []
  
  static func makeContext() -> AppContext {
    let id = dispatcher.makeSessionState()
    let context = AppContext(sessionStateID: id)
    activeContexts.append(context)
    return context
  }
}

final class ApplicationDispatcher: Dispatcher<AppState> {
  
  fileprivate init() {
    super.init(target: ApplicationContainer.store)
  }
  
  func makeSessionState() -> SessionState.ID {
    
    let state = SessionState()
    
    commit {
      $0.sessions[state.id] = state
    }
    
    return state.id
    
  }
  
}

final class AppContext {
  
  let sessionStateID: String
    
  let stack: Stack
  
  init(sessionStateID: String) {
    self.stack = .init(sessionStateID: sessionStateID)
    self.sessionStateID = sessionStateID
  }
}

final class Stack {
  
  let service: Service
  
  init(sessionStateID: String) {
    
    self.service = Service(sessionStateID: sessionStateID)
  }
}

final class Service: Dispatcher<AppState>, ScopedDispatching {
  
  let selector: WritableKeyPath<Service.State, SessionState>
  
  init(sessionStateID: String) {
    self.selector = \AppState.sessions[sessionStateID]!
    super.init(target: ApplicationContainer.store)
  }
  
  func globalIncrement() {
    
    commit {
      $0.count += 1
    }
    
  }
  
  func increment() {
    
    commitScoped {
      $0.count += 1
    }
        
  }
}
