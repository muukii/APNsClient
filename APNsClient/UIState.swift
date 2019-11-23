//
//  UIState.swift
//  APNsClient
//
//  Created by muukii on 2019/11/24.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import VergeStore

import Backend

struct UIState {
  
  struct EditingPush: Identifiable {
    let id: String = UUID().uuidString
    var name: String
    var data: DraftPushData = .init()
  }
  
  var editingPushesTable: [EditingPush.ID : EditingPush] = [:]
  var editingPushIDs: [EditingPush.ID] = []
  
  func editingPushes() -> [EditingPush] {
    editingPushIDs.compactMap {
      editingPushesTable[$0]
    }
  }
  
  func editingPush(by id: EditingPush.ID) -> EditingPush? {
    editingPushesTable[id]
  }
    
}

extension SessionState {
  
  var ui: UIState {
    get {
      _ui as! UIState
    }
    set {
      _ui = newValue
    }
  }
}

final class SessionUIDispatcher: Dispatcher<AppState>, ScopedDispatching {
  
  public let selector: WritableKeyPath<SessionService.State, SessionState>
  
  init(sessionStateID: String) {
    self.selector = \AppState.sessions[sessionStateID]!
    super.init(target: ApplicationContainer.store)
    commitScoped {
      if $0._ui == nil {
        $0.ui = .init()
      }
    }
  }
  
  func addTab() {
    
    commitScoped {
      let push = UIState.EditingPush(name: "Untitled")
      $0.ui.editingPushesTable[push.id] = push
      $0.ui.editingPushIDs.append(push.id)
    }
    
  }
  
  func updateEditingPush(_ editingPush: UIState.EditingPush) {
    commitScoped {
      $0.ui.editingPushesTable[editingPush.id] = editingPush
    }
  }
  
}
