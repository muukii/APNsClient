//
//  Service.swift
//  Service
//
//  Created by muukii on 2019/11/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import Combine

import Verge
import APNSwift
import NIO

public typealias APNEnvironment = APNSwiftConfiguration.Environment

public final class SessionService: Store.ScopedDispatcher<SessionState> {
      
  fileprivate let queue: DispatchQueue = .init(label: "push")
  
  let sessionStateID: String
  
  init(sessionStateID: String) {
    self.sessionStateID = sessionStateID
    super.init(targetStore: ApplicationContainer.store, scope: \AppState.sessions[sessionStateID]!)
  }
  
  public func globalIncrement() {
    commit(scope: \.self) {
      $0.count += 1
    }
  }
  
  public func increment() {
    commit {
      $0.count += 1
    }
  }
  
  public func setP8FileURL(_ url: URL) {
    commit {
      $0.p8FileURL = url
    }
  }
  
  @discardableResult
  public func send(
    keyID: String,
    teamID: String,
    topic: String,
    enviroment: APNSwiftConfiguration.Environment,
    payload: String,
    deviceToken: String
  ) -> Future<Void, Error> {
    
    Future<Void, Error>.init { (promise) in
      self.queue.async {
        guard let url = self.state.p8FileURL else { return }
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
          
          try apns.close().wait()
          try group.syncShutdownGracefully()
          
          print(res)
          
          promise(.success(()))
          
        } catch {
          
          print(error)
          promise(.failure(error))
          
        }
      }
    }
    
  }
}
