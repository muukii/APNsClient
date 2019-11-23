//
//  Service.swift
//  Service
//
//  Created by muukii on 2019/11/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import VergeStore
import APNSwift
import NIO

public final class SessionService: Dispatcher<AppState>, ScopedDispatching {
  
  public let selector: WritableKeyPath<SessionService.State, SessionState>
  
  init(sessionStateID: String) {
    self.selector = \AppState.sessions[sessionStateID]!
    super.init(target: ApplicationContainer.store)
  }
  
  public func globalIncrement() {
    
    commit {
      $0.count += 1
    }
    
  }
  
  public func increment() {
    
    commitScoped {
      $0.count += 1
    }
    
  }
  
  public func setP8FileURL(_ url: URL) {
    commitScoped {
      $0.p8FileURL = url
    }
  }
  
  public func send(
    keyID: String,
    teamID: String,
    topic: String,
    enviroment: APNSwiftConfiguration.Environment,
    payload: String,
    deviceToken: String
  ) {
        
    do {
      
      let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
      let signer = try! APNSwiftSigner(filePath: "xxx.p8")
      
      let apnsConfig = APNSwiftConfiguration(
        keyIdentifier: keyID,
        teamIdentifier: teamID,
        signer: signer,
        topic: topic,
        environment: enviroment
      )
      
      struct BasicNotification: APNSwiftNotification {
        var aps: APNSwiftPayload
      }
      let apns = try APNSwiftConnection.connect(configuration: apnsConfig, on: group.next()).wait()
//      let alert = APNSwiftPayload.APNSwiftAlert(title: "Hey There", subtitle: "Full moon sighting", body: "There was a full moon last night did you see it")
//      let aps = APNSwiftPayload(alert: alert, badge: 1, sound: .normal("cow.wav"))
//      let notification = BasicNotification(aps: aps)
      
      var allocator = ByteBufferAllocator().buffer(capacity: payload.utf8.count)
      allocator.writeBytes(Array(payload.utf8))
            
      let res = apns.send(rawBytes: allocator, pushType: .alert, to: deviceToken)
      print(res)
      
      try apns.close().wait()
      try group.syncShutdownGracefully()
      
    } catch {
      
      print(error)
      
    }
  }
}
