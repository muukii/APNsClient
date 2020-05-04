//
// Copyright (c) 2020 Hiroshi Kimura(Muukii) <muuki.app@gmail.com>
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

/**
 A protocol that wraps Store inside and provides the functions of DispatcherType
 
 Especially, it would be helpful to migrate from Verge classic.
 
 ```
 class MyViewModel: StoreWrapperType {
 
   // Current restriction, you need put the typealias as Scope points to State.
   typealias Scope = State
   
   struct State: StateType {
     ...
   }
   
   enum Activity {
     ...
   }
   
   let store: Store<State, Activity>
 
   init() {
     self.store = .init(initialState: .init(), logger: nil)
   }
 
 }
 ``` 
 */
public protocol StoreWrapperType: StoreType, DispatcherType {
  
  associatedtype State = WrappedStore.State
  associatedtype Activity = WrappedStore.Activity
    
  associatedtype Scope
  var store: WrappedStore { get }
}

extension StoreWrapperType {
  public typealias DefaultStore = Store<State, Activity>
}

extension StoreWrapperType where State == WrappedStore.State, Activity == WrappedStore.Activity {
  public func asStore() -> Store<State, Activity> {
    store.asStore()
  }
}

extension StoreWrapperType {
      
  public var changes: Changes<WrappedStore.State> {
    store.asStore().changes
  }
  
  public var state: WrappedStore.State {
    store.state
  }
  
  /// Subscribe the state changes
  ///
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  public func subscribeChanges(
    dropsFirst: Bool = false,
    queue: DispatchQueue? = nil,
    receive: @escaping (Changes<WrappedStore.State>) -> Void
  ) -> VergeAnyCancellable {
    store.asStore().subscribeChanges(dropsFirst: dropsFirst, queue: queue, receive: receive)
  }
  
  /// Subscribe the activity
  ///
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  public func subscribeActivity(
    queue: DispatchQueue? = nil,
    receive: @escaping (WrappedStore.Activity) -> Void
  ) -> VergeAnyCancellable  {
    store.asStore().subscribeActivity(queue: queue, receive: receive)
  }
      
}

#if canImport(Combine)

import Combine

@available(iOS 13, macOS 10.15, *)
extension StoreWrapperType where State == WrappedStore.State, Activity == WrappedStore.Activity {
  
  public var statePublisher: AnyPublisher<State, Never> {
    store.asStore().statePublisher
  }
  
  public func changesPublisher(startsFromInitial: Bool = true) -> AnyPublisher<Changes<State>, Never> {
    store.asStore().changesPublisher(startsFromInitial: startsFromInitial)
  }
  
  public var activityPublisher: EventEmitter<Activity>.Publisher {
    store.asStore().activityPublisher
  }
  
}

#endif
