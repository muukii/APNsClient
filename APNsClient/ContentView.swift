//
//  ContentView.swift
//  APNsClient
//
//  Created by muukii on 2019/11/21.
//  Copyright © 2019 muukii. All rights reserved.
//

import SwiftUI

struct ContentView: View {
  
  let appContext: AppContext
  
  @EnvironmentObject var store: Store
  
  var state: SessionState {
    store.state.sessions[appContext.sessionStateID]!
  }
    
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
      HStack {
        Text("Global") + Text(store.state.count.description).foregroundColor(.red)
        
        Text("Session") + Text(state.count.description).foregroundColor(.blue)
      }
      
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
      
      EditableTextView(text: $payload)
        .font(Font.system(.body, design: .monospaced))
      
      Button(action: {}) {
        Text("Send")
      }
      
      Button(action: {
        self.appContext.stack.service.globalIncrement()
      }) {
        Text("Global")
      }
      
      Button(action: {
        self.appContext.stack.service.increment()
      }) {
        Text("Sesson")
      }
    }
    .padding(24)
    .frame(minWidth: 300, minHeight: 500)
  }
}
