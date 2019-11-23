//
//  TabView.swift
//  APNsClient
//
//  Created by muukii on 2019/11/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation
import SwiftUI

import Backend

struct MainTabView: View {
  
  @EnvironmentObject var store: Store
  @EnvironmentObject var uiDispatcher: SessionUIDispatcher
  
  @State var selected: UIState.EditingPush.ID?
  
  let context: AppContext  
  let sessionState: SessionState
  
  private var uiState: UIState {
    sessionState.ui
  }
    
  private func currentEditor() -> AnyView {
    
    if let id = selected {
      return AnyView(PushEditorView(
        id: id,
        editing: Binding<UIState.EditingPush>.init(
          get: {
            self.uiState.editingPush(by: id)!
        },
          set: { editing in
            self.uiDispatcher.updateEditingPush(editing)
        })
        )
      )
    } else {
      return AnyView(Spacer())
    }
  }
  
  var body: some View {
           
    VStack {
      Button(action: {
        self.uiDispatcher.addTab()
      }) {
        Text("New Tab")
      }
      HStack {
        List {
          ForEach(uiState.editingPushes()) { (item) in
            EditingItem(title: item.name, isSelected: self.selected == item.id)
              .onTapGesture {
                self.selected = item.id
            }
          }
        }
        .frame(width: 100)
        
        currentEditor()
          .frame(minWidth: 300)

      }
    }
  }
}

struct EditingItem: View {
  
  let title: String
  let isSelected: Bool
  
  var body: some View {
    Text(title)
      .font(.body)
      .foregroundColor(.white)
      .background(isSelected ? Color.blue : Color.clear)
  }
}
