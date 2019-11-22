//
//  RootView.swift
//  APNsClient
//
//  Created by muukii on 2019/11/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import SwiftUI

struct RootView: View {
  
  @EnvironmentObject var store: Store
  
  var context: AppContext
  
  var body: some View {
    ContentView(appContext: context)
  }
}

