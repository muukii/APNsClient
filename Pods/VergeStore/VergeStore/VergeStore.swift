//
// Copyright (c) 2019 muukii
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

public struct MutationMetadata {
  
  public let name: String
  public let file: StaticString
  public let function: StaticString
  public let line: UInt
  
}

public struct ActionMetadata {
  
  public let name: String
  public let file: StaticString
  public let function: StaticString
  public let line: UInt
  
}

public protocol VergeStoreLogger {
  
  func willCommit(store: AnyObject, state: Any, mutation: MutationMetadata, context: AnyObject?)
  func didCommit(store: AnyObject, state: Any, mutation: MutationMetadata, context: AnyObject?)
  func didDispatch(store: AnyObject, state: Any, action: ActionMetadata, context: AnyObject?)
  
  func didCreateDispatcher(store: AnyObject, dispatcher: Any)
  func didDestroyDispatcher(store: AnyObject, dispatcher: Any)
  
  func didTakeTimeToCommit(store: AnyObject, state: Any, mutation: MutationMetadata, time: CFTimeInterval)
}

open class VergeDefaultStore<State>: CustomReflectable {
  
  public typealias DispatcherType = Dispatcher<State>
  
  public var state: State {
    storage.value
  }
  
  let storage: Storage<State>
  
  public private(set) var logger: VergeStoreLogger?
  
  public init(
    initialState: State,
    logger: VergeStoreLogger?
  ) {
    
    self.storage = .init(initialState)
    self.logger = logger
    
  }
  
  func receive<FromDispatcher: Dispatching>(
    context: VergeStoreDispatcherContext<FromDispatcher>?,
    metadata: MutationMetadata,
    mutation: (inout State) throws -> Void
  ) rethrows {
    
    logger?.willCommit(store: self, state: self.state, mutation: metadata, context: context)
    defer {
      logger?.didCommit(store: self, state: self.state, mutation: metadata, context: context)
    }
    
    let startedTime = CFAbsoluteTimeGetCurrent()
    try storage.update { (state) in
      try mutation(&state)
    }
    let elapsed = CFAbsoluteTimeGetCurrent() - startedTime
    
    logger?.didTakeTimeToCommit(
      store: self,
      state: self.state,
      mutation: metadata,
      time: elapsed
    )
       
  }
  
  public var customMirror: Mirror {
    Mirror(
      self,
      children: [
        "state": state
      ],
      displayStyle: .struct
    )
  }
      
}

#if canImport(Combine)

import Foundation
import Combine

private var _associated: Void?

@available(iOS 13.0, macOS 10.15, *)
extension Storage: ObservableObject {
  
  public var objectWillChange: ObservableObjectPublisher {
    if let associated = objc_getAssociatedObject(self, &_associated) as? ObservableObjectPublisher {
      return associated
    } else {
      let associated = ObservableObjectPublisher()
      objc_setAssociatedObject(self, &_associated, associated, .OBJC_ASSOCIATION_RETAIN)
      
      add { _ in
        if Thread.isMainThread {
          associated.send()
        } else {
          DispatchQueue.main.async {
            associated.send()
          }
        }
      }
      
      return associated
    }
  }
}

@available(iOS 13.0, macOS 10.15, *)
extension VergeDefaultStore: ObservableObject {
  public var objectWillChange: ObservableObjectPublisher {
    storage.objectWillChange
  }
}

@available(iOS 13.0, macOS 10.15, *)
extension Dispatcher: ObservableObject {

}

#endif
