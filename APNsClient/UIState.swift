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

extension DispatcherContext where Dispatcher : SessionUIDispatcher {
  
  var scopedState: SessionState {
    state.sessions[dispatcher.sessionStateID]!
  }
}

final class SessionUIDispatcher: Backend.Store.Dispatcher {
  
  public let scopedStateKeyPath: WritableKeyPath<SessionService.State, SessionState>
  
  fileprivate let queue = DispatchQueue(label: "save")
  fileprivate let encoder = JSONEncoder()
  fileprivate let decoder = JSONDecoder()
  
  fileprivate let sessionStateID: String
  
  init(sessionStateID: String) {
    self.sessionStateID = sessionStateID
    self.scopedStateKeyPath = \AppState.sessions[sessionStateID]!
    super.init(target: ApplicationContainer.store)
    dispatch { $0.restoreState() }
  }
      
  func setInitialState() -> Mutation<Void> {
    return .mutation(scopedStateKeyPath) {
      if $0._ui == nil {
        $0.ui = .init()
      }
    }
  }
  
  fileprivate func addTab() -> Mutation<Void> {
    return .mutation(scopedStateKeyPath) {
      let push = UIState.EditingPush(name: "Untitled")
      $0.ui.editing.editingPushesTable[push.id] = push
      $0.ui.editing.editingPushIDs.append(push.id)
    }
  }
  
  fileprivate func updateEditingPush(_ editingPush: UIState.EditingPush) -> Mutation<Void> {
    return .mutation(scopedStateKeyPath) {
      $0.ui.editing.editingPushesTable[editingPush.id] = editingPush
    }
  }
  
  fileprivate func deleteEditingPush(_ editingPush: UIState.EditingPush) -> Mutation<Void> {
     return .mutation(scopedStateKeyPath) { s in
      s.ui.editing.editingPushesTable.removeValue(forKey: editingPush.id)
      s.ui.editing.editingPushIDs.removeAll { $0 == editingPush.id }
    }
  }
  
  fileprivate func updateUIEditing(_ editing: UIState.Editing) -> Mutation<Void> {
     return .mutation(scopedStateKeyPath) {
      $0.ui.editing = editing
    }
  }
  
  func addTab() -> Action<Void> {
    return .action { c in
      c.commit { $0.addTab() }
      c.dispatch { $0.saveCurrentEditing() }
    }
  }
  
  func updateEditingPush(_ editingPush: UIState.EditingPush) -> Action<Void> {
    return .action { c in
      c.commit { $0.updateEditingPush(editingPush) }
      c.dispatch { $0.saveCurrentEditing() }
    }
    
  }
  
  func deleteEditingPush(_ editingPush: UIState.EditingPush) -> Action<Void> {
    return .action { c in
      c.commit { $0.deleteEditingPush(editingPush) }
      c.dispatch { $0.saveCurrentEditing() }
    }
    
  }
  
  func restoreState() -> Action<Void> {
    // TODO: For now we use very bad performance code,
     return .action { c in
      c.commit { $0.setInitialState() }
      self.queue.async {
        if let data = UserDefaults.standard.data(forKey: "editing") {
          
          let editing = try! self.decoder.decode(UIState.Editing.self, from: data)
          c.commit { $0.updateUIEditing(editing) }
        }
      }
    }
  }
  
  private func saveCurrentEditing() -> Action<Void> {
    return .action { c in
      
      // TODO: For now we use very bad performance code,
      self.queue.async {
        
        let data = try! self.encoder.encode(c.scopedState.ui.editing)
        
        UserDefaults.standard.set(data, forKey: "editing")
        
      }
    }
  }
}
