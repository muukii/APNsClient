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
      
  @State var bundleID: String = ""
  @State var keyID: String = ""
  @State var teamID: String = ""
  @State var payload: String = ""
  @State var deviceToken: String = ""
  
  @State var isProduction: Bool = true
  
  private var enviroment: String {
    isProduction ? "Production" : "Development"
  }
  
  var body: some View {
    VStack {
         
      Group {
        
        TextField("Bundle Identifier", text: $bundleID, onEditingChanged: { _ in }, onCommit: {})
        
        TextField("KeyID", text: $keyID, onEditingChanged: { _ in }, onCommit: {})
        
        TextField("TeamID", text: $teamID, onEditingChanged: { _ in }, onCommit: {})
        
        TextField("Device Token", text: $deviceToken, onEditingChanged: { _ in }, onCommit: {})
        
        MenuButton(label: Text(enviroment)) {
          Button(action: {
            self.isProduction = true
          }) { Text("Production") }
          Button(action: {
            self.isProduction = false
          }) { Text("Development") }
        }
      }
      
      EditableTextView(text: $payload)
        .font(Font.system(.body, design: .monospaced))
      
      Button(action: {}) {
        Text("Send")
      }
      
    }

  }
}
