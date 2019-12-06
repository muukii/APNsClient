//
//  Service.swift
//  Service
//
//  Created by muukii on 2019/11/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import Combine

import VergeStore
import APNSwift
import NIO

public typealias APNEnvironment = APNSwiftConfiguration.Environment

public final class SessionService: Dispatcher<AppState>, ScopedDispatching {
  
  public let scopedStateKeyPath: WritableKeyPath<AppState, SessionState>
  
  fileprivate let queue: DispatchQueue = .init(label: "push")
  
  init(sessionStateID: String) {
    self.scopedStateKeyPath = \AppState.sessions[sessionStateID]!
    super.init(target: ApplicationContainer.store)
  }
  
}

extension Mutations where Base : SessionService {
  public func globalIncrement() {
    
    descriptor.commit {
      $0.count += 1
    }
    
  }
  
  public func increment() {
    
    descriptor.commitScoped {
      $0.count += 1
    }
    
  }
  
  public func setP8FileURL(_ url: URL) {
    descriptor.commitScoped {
      $0.p8FileURL = url
    }
  }
  
}

extension Actions where Base : SessionService {
  
  @discardableResult
  public func send(
    keyID: String,
    teamID: String,
    topic: String,
    enviroment: APNSwiftConfiguration.Environment,
    payload: String,
    deviceToken: String
  ) -> Future<Void, Error> {
    
    descriptor.dispatch { (c) in
      
      Future<Void, Error>.init { (promise) in
        self.base.queue.async {
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
