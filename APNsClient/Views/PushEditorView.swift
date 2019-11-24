//
//  DispatchPushView.swift
//  APNsClient
//
//  Created by muukii on 2019/11/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation
import SwiftUI

struct PushEditorView: View {
  
  let id: String
  @Binding var editing: UIState.EditingPush
  
  var onRequestedSend: (UIState.EditingPush) -> Void
  var onRequestedDelete: (UIState.EditingPush) -> Void
                   
  private var enviroment: String {
    editing.data.enviroment == .production ? "Production" : "Development"
  }
  
  var body: some View {
        
    VStack {
      
      Button(action: {
        self.onRequestedDelete(self.editing)
      }) {
        Text("Delete")
      }
               
      Group {
        
        TextField("Name", text: $editing.name, onEditingChanged: { _ in }, onCommit: {})
        
        TextField("Bundle Identifier", text: $editing.data.bundleID, onEditingChanged: { _ in }, onCommit: {})
        
        TextField("KeyID", text: $editing.data.keyID, onEditingChanged: { _ in }, onCommit: {})
        
        TextField("TeamID", text: $editing.data.teamID, onEditingChanged: { _ in }, onCommit: {})
        
        TextField("Device Token", text: $editing.data.deviceToken, onEditingChanged: { _ in }, onCommit: {})
        
        MenuButton(label: Text(enviroment)) {
          Button(action: {
            self.editing.data.enviroment = .production
          }) { Text("Production") }
          Button(action: {
            self.editing.data.enviroment = .sandbox
          }) { Text("Development") }
        }
      }
      
      EditableTextView(text: $editing.data.payload)
        .font(Font.system(.body, design: .monospaced))
      
      Button(action: {
        self.onRequestedSend(self.editing)
      }) {
        Text("Send")
      }
      
    }

  }
}
