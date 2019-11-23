//
//  AppDelegate.swift
//  APNsClient
//
//  Created by muukii on 2019/11/21.
//  Copyright © 2019 muukii. All rights reserved.
//

import Cocoa
import SwiftUI

import Backend

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  var window: NSWindow!


  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Create the SwiftUI view that provides the window contents.
    
    let context = ApplicationContainer.makeContext()
    let uiDispatcher = SessionUIDispatcher(sessionStateID: context.sessionStateID)
    
    let rootView = RootView(context: context)
      .environmentObject(ApplicationContainer.store)
      .environmentObject(uiDispatcher)
        
    ProcessInfo.processInfo.disableAutomaticTermination("")

    // Create the window and set the content view. 
    window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
        styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
        backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    window.center()
    window.setFrameAutosaveName("Main Window")
    window.contentView = NSHostingView(rootView: rootView)
    window.makeKeyAndOrderFront(nil)
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
  
  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    window?.makeKeyAndOrderFront(nil)
    return false
  }
}

