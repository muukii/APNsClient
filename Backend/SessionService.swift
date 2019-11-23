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
  
  private let queue: DispatchQueue = .init(label: "push")
  
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
    
    dispatch { (c) in
      
      queue.async {
        guard let url = c.scopedState.p8FileURL else { return }
        do {
          
          let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
          let signer = try! APNSwiftSigner(filePath: url.path)
          
          let apnsConfig = APNSwiftConfiguration(
            keyIdentifier: keyID,
            teamIdentifier: teamID,
            signer: signer,
            topic: topic,
            environment: enviroment
          )
          
          let apns = try APNSwiftConnection.connect(configuration: apnsConfig, on: group.next()).wait()
          
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
    
  }
}
