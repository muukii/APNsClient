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

final class SessionUIDispatcher: Backend.Store.ScopedDispatcher<SessionState> {
    
  fileprivate let queue = DispatchQueue(label: "save")
  fileprivate let encoder = JSONEncoder()
  fileprivate let decoder = JSONDecoder()
  
  fileprivate let sessionStateID: String
  
  init(sessionStateID: String) {
    self.sessionStateID = sessionStateID
    super.init(targetStore: ApplicationContainer.store, scope: \AppState.sessions[sessionStateID]!)
    
    restoreState()
  }
      
  func setInitialState() {
    commit {
      if $0._ui == nil {
        $0.ui = .init()
      }
    }
  }
       
  fileprivate func updateUIEditing(_ editing: UIState.Editing) {
    commit {
      $0.ui.editing = editing
    }
  }
  
  func addTab() {
    commit {
      let push = UIState.EditingPush(name: "Untitled")
      $0.ui.editing.editingPushesTable[push.id] = push
      $0.ui.editing.editingPushIDs.append(push.id)
    }
    saveCurrentEditing()
  }
  
  func updateEditingPush(_ editingPush: UIState.EditingPush) {
    commit {
      $0.ui.editing.editingPushesTable[editingPush.id] = editingPush
    }
    saveCurrentEditing()
  }
  
  func deleteEditingPush(_ editingPush: UIState.EditingPush) {
    commit {
      $0.ui.editing.editingPushesTable.removeValue(forKey: editingPush.id)
      $0.ui.editing.editingPushIDs.removeAll { $0 == editingPush.id }
    }
    saveCurrentEditing()
  }
  
  func restoreState() {
    // TODO: For now we use very bad performance code,
     setInitialState()
    self.queue.async {
      if let data = UserDefaults.standard.data(forKey: "editing") {
        
        let editing = try! self.decoder.decode(UIState.Editing.self, from: data)
        self.updateUIEditing(editing)
      }
    }
  }
  
  private func saveCurrentEditing() {
    // TODO: For now we use very bad performance code,
    self.queue.async {
      
      let data = try! self.encoder.encode(self.state.ui.editing)
      
      UserDefaults.standard.set(data, forKey: "editing")
    }
  }
}
