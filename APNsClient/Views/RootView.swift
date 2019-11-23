//
//  RootView.swift
//  APNsClient
//
//  Created by muukii on 2019/11/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import SwiftUI

import Backend

struct RootView: View {
  
  @EnvironmentObject var store: Store
  @EnvironmentObject var uiDispatcher: SessionUIDispatcher
  
  var sessionState: SessionState {
    store.state.sessions[context.sessionStateID]!
  }
  
  let context: AppContext
  
  var body: some View {
    MainTabView(context: context, sessionState: sessionState)
  }
}

