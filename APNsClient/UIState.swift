//
//  UIState.swift
//  APNsClient
//
//  Created by muukii on 2019/11/24.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import Combine
import Verge

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
  
  typealias Scoped = SessionState
  
  public let scopedStateKeyPath: WritableKeyPath<SessionService.State, SessionState>
  
  fileprivate let queue = DispatchQueue(label: "save")
  fileprivate let encoder = JSONEncoder()
  fileprivate let decoder = JSONDecoder()
  
  init(sessionStateID: String) {
    self.scopedStateKeyPath = \AppState.sessions[sessionStateID]!
    super.init(target: ApplicationContainer.store)
    
    dispatch.restoreState()
  }
      
}

extension Mutations where Base : SessionUIDispatcher {
  
  func setInitialState() {
    descriptor.commitScoped {
      if $0._ui == nil {
        $0.ui = .init()
      }
    }
  }
  
  fileprivate func addTab() {
        
    descriptor.commitScoped {
      let push = UIState.EditingPush(name: "Untitled")
      $0.ui.editing.editingPushesTable[push.id] = push
      $0.ui.editing.editingPushIDs.append(push.id)
    }
            
  }
  
  fileprivate func updateEditingPush(_ editingPush: UIState.EditingPush) {
    
    descriptor.commitScoped { s in
      s.ui.editing.editingPushesTable[editingPush.id] = editingPush
    }
  }
  
  fileprivate func deleteEditingPush(_ editingPush: UIState.EditingPush) {
    descriptor.commitScoped { s in
      s.ui.editing.editingPushesTable.removeValue(forKey: editingPush.id)
      s.ui.editing.editingPushIDs.removeAll { $0 == editingPush.id }
    }
  }
  
  fileprivate func updateUIEditing(_ editing: UIState.Editing) {
    descriptor.commitScoped {
      $0.ui.editing = editing
    }
  }
}

extension Actions where Base : SessionUIDispatcher {
  
  func addTab() {
    
    descriptor.dispatch { c in
      c.commit.addTab()
      c.dispatch.saveCurrentEditing()
    }
    
  }
  
  func updateEditingPush(_ editingPush: UIState.EditingPush) {
    
    descriptor.dispatch { c in
      c.commit.updateEditingPush(editingPush)
      c.dispatch.saveCurrentEditing()
    }
              
  }
  
  func deleteEditingPush(_ editingPush: UIState.EditingPush) {
    
    descriptor.dispatch { c in
      c.commit.deleteEditingPush(editingPush)
      c.dispatch.saveCurrentEditing()
    }
    
  }
  
  func restoreState() {
    // TODO: For now we use very bad performance code,
    descriptor.dispatch { c -> Void in
      c.commit.setInitialState()
      base.queue.async {
        if let data = UserDefaults.standard.data(forKey: "editing") {
          
          let editing = try! self.base.decoder.decode(UIState.Editing.self, from: data)
          c.commit.updateUIEditing(editing)
        }
      }
    }
  }
  
  private func saveCurrentEditing() {
    descriptor.dispatch { c in
      
      // TODO: For now we use very bad performance code,      
      base.queue.async {
        
        let data = try! self.base.encoder.encode(c.scopedState.ui.editing)
        
        UserDefaults.standard.set(data, forKey: "editing")
        
      }
    }
  }
}
