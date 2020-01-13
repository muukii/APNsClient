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

open class ReadonlyStorage<Value>: CustomReflectable {
    
  private let willUpdateEmitter = EventEmitter<Void>()
  private let didUpdateEmitter = EventEmitter<Value>()
  private let deinitEmitter = EventEmitter<Void>()
  
  public final var wrappedValue: Value {
    return value
  }
  
  public final var value: Value {
    _lock.lock()
    defer {
      _lock.unlock()
    }
    return nonatomicValue
  }
  
  fileprivate var nonatomicValue: Value
  
  let _lock = NSRecursiveLock()
  
  fileprivate let upstreams: [AnyObject]
  
  public init(_ value: Value, upstreams: [AnyObject] = []) {
    self.nonatomicValue = value
    self.upstreams = upstreams
  }
  
  deinit {
    deinitEmitter.accept(())
  }
    
  /// Register observer with closure.
  /// Storage tells got a newValue.
  /// - Returns: Token to stop subscribing. (Optional) You may need to retain somewhere. But subscription will be disposed when Storage was destructed.
  @discardableResult
  public final func addWillUpdate(subscriber: @escaping () -> Void) -> EventEmitterSubscribeToken {
    willUpdateEmitter.add(subscriber)
  }
  
  /// Register observer with closure.
  /// Storage tells got a newValue.
  /// - Returns: Token to stop subscribing. (Optional) You may need to retain somewhere. But subscription will be disposed when Storage was destructed.
  @discardableResult
  public final func addDidUpdate(subscriber: @escaping (Value) -> Void) -> EventEmitterSubscribeToken {
    didUpdateEmitter.add(subscriber)
  }
  
  @discardableResult
  public final func addDeinit(subscriber: @escaping () -> Void) -> EventEmitterSubscribeToken {
    deinitEmitter.add(subscriber)
  }
  
  public final func remove(subscribe token: EventEmitterSubscribeToken) {
    didUpdateEmitter.remove(token)
    willUpdateEmitter.remove(token)
    deinitEmitter.remove(token)
  }
    
  @inline(__always)
  fileprivate func notifyWillUpdate(value: Value) {
    willUpdateEmitter.accept(())
  }
  
  @inline(__always)
  fileprivate func notifyDidUpdate(value: Value) {
    didUpdateEmitter.accept(value)
  }
  
  public var customMirror: Mirror {
    Mirror(
      self,
      children: ["value": value],
      displayStyle: .struct
    )
  }
  
}

open class Storage<Value>: ReadonlyStorage<Value> {
  
  @discardableResult
  @inline(__always)
  public final func update<Result>(_ update: (inout Value) throws -> Result) rethrows -> Result {
    let signpost = VergeSignpostTransaction("Storage.update")
    defer {
      signpost.end()
    }
    do {
      let notifyValue: Value
      _lock.lock()
      notifyValue = nonatomicValue
      _lock.unlock()
      notifyWillUpdate(value: notifyValue)
    }
    
    _lock.lock()
    do {
      let r = try update(&nonatomicValue)
      let notifyValue = nonatomicValue
      _lock.unlock()
      notifyDidUpdate(value: notifyValue)
      return r
    } catch {
      _lock.unlock()
      throw error
    }
  }
  
  public final func replace(_ value: Value) {
    do {
      let notifyValue: Value
      _lock.lock()
      notifyValue = nonatomicValue
      _lock.unlock()
      notifyWillUpdate(value: notifyValue)
    }
    
    do {
      _lock.lock()
      nonatomicValue = value
      let notifyValue = nonatomicValue
      _lock.unlock()
      notifyDidUpdate(value: notifyValue)
    }
  }
  
}

extension ReadonlyStorage {
  
  /// Transform value with filtering.
  /// - Attention: Retains upstream storage
  public func map<U>(
    onUpdated: @escaping (Value) -> Void = { _ in },
    onPassed: @escaping (Value) -> Void = { _ in },
    filter: @escaping (Value) -> Bool = { _ in false },
    transform: @escaping (Value) -> U
  ) -> ReadonlyStorage<U> {
    
    let initialValue = transform(value)
    let newStorage = Storage<U>.init(initialValue, upstreams: [self])
    
    let token = addDidUpdate { [weak newStorage] (newValue) in
      guard !filter(newValue) else {
        onPassed(newValue)
        return
      }
      newStorage?.replace(transform(newValue))
      onUpdated(newValue)
    }
    
    newStorage.addDeinit { [weak self] in
      self?.remove(subscribe: token)
    }
    
    return newStorage
  }
}
