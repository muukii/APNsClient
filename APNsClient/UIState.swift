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
  
  struct EditingPush: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var data: DraftPushData = .init()
  }
  
  struct Editing: Codable {
    var editingPushesTable: [EditingPush.ID : EditingPush] = [:]
    var editingPushIDs: [EditingPush.ID] = []
  }
  
  var editing: Editing = .init()
  
  func editingPushes() -> [EditingPush] {
    editing.editingPushIDs.compactMap {
      editing.editingPushesTable[$0]
    }
  }
  
  func editingPush(by id: EditingPush.ID) -> EditingPush? {
    editing.editingPushesTable[id]
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
  
  private let queue = DispatchQueue(label: "save")
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()
  
  init(sessionStateID: String) {
    self.selector = \AppState.sessions[sessionStateID]!
    super.init(target: ApplicationContainer.store)
    commitScoped {
      if $0._ui == nil {
        $0.ui = .init()
      }
    }
    
    // TODO: Temp
    dispatch { c in
      queue.async {
        if let data = UserDefaults.standard.data(forKey: "editing") {
          
          let editing = try! self.decoder.decode(UIState.Editing.self, from: data)
          c.commitScoped {
            $0.ui.editing = editing
          }
        }
      }
    }
  }
  
  func addTab() {
    
    commitScoped {
      let push = UIState.EditingPush(name: "Untitled")
      $0.ui.editing.editingPushesTable[push.id] = push
      $0.ui.editing.editingPushIDs.append(push.id)
    }
    
  }
  
  func updateEditingPush(_ editingPush: UIState.EditingPush) {
        
    commitScoped {
      $0.ui.editing.editingPushesTable[editingPush.id] = editingPush
    }
    
    dispatch { c in
      
      // TODO: Temp
      queue.async {
        
        let data = try! self.encoder.encode(c.scopedState.ui.editing)
        
        UserDefaults.standard.set(data, forKey: "editing")
        
      }
    }
        
   
  }
  
}
