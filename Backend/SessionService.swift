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

extension DispatcherContext where Dispatcher : SessionService {
  
  var scopedState: SessionState {
    state.sessions[dispatcher.sessionStateID]!
  }
}

public final class SessionService: Store.Dispatcher {
      
  private let scopedStateKeyPath: WritableKeyPath<AppState, SessionState>
  
  fileprivate let queue: DispatchQueue = .init(label: "push")
  
  let sessionStateID: String
  
  init(sessionStateID: String) {
    self.scopedStateKeyPath = \AppState.sessions[sessionStateID]!
    self.sessionStateID = sessionStateID
    super.init(target: ApplicationContainer.store)
  }
  
  public func globalIncrement() -> Mutation<Void> {
    return .mutation {
      $0.count += 1
    }
  }
  
  public func increment() -> Mutation<Void>  {
    return .mutation(scopedStateKeyPath) { (s) in
      s.count += 1
    }
  }
  
  public func setP8FileURL(_ url: URL) -> Mutation<Void>  {
    return .mutation(scopedStateKeyPath) { (s) in
      s.p8FileURL = url
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
  ) -> Action<Future<Void, Error>> {
    return .action { c in
      
      Future<Void, Error>.init { (promise) in
        self.queue.async {
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
}
