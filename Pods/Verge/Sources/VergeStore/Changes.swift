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

#if !COCOAPODS
import VergeCore
#endif

public protocol ChangesType: AnyObject {
  
  associatedtype Value
  var old: Value? { get }
  var current: Value { get }
  
  func asChanges() -> Changes<Value>
}

/**
 
 An object that contains 2 instances (old, new)
 Use-case is to know how it did change.
 
 ```
 struct MyState {
   var name: String
   var age: String
   var height: String
 }
 ```
 
 ```
 let changes: Changes<MyState>
 ```
 
 It can be accessed with properties of MyState by dynamicMemberLookup
 ```
 changes.name
 ```
 
 It would be helpful to update UI partially
 ```
 func updateUI(changes: Changes<MyState>) {
 
   changes.ifChanged(\.name) { name in
   // update UI
   }
   
   changes.ifChanged(\.age) { age in
   // update UI
   }
   
   changes.ifChanged(\.height) { height in
   // update UI
   }
 }
 ```
 */
@dynamicMemberLookup
public final class Changes<Value>: ChangesType {
  
  // MARK: - Stored Properties

  let previous: Changes<Value>?
  private let innerCurrent: InnerCurrent
  private(set) public var version: UInt64
  
  // MARK: - Computed Properties
    
  public var old: Value? { _read { yield previous?.current } }
  public var current: Value { _read { yield innerCurrent.value } }
  
  // MARK: - Initializers
    
  public convenience init(
    old: Value?,
    new: Value
  ) {
    self.init(
      previous: nil,
      innerCurrent: .init(value: new),
      version: 0
    )
  }
  
  private init(
    previous: Changes<Value>?,
    innerCurrent: InnerCurrent,
    version: UInt64
  ) {
    
    self.previous = previous
    self.innerCurrent = innerCurrent
    self.version = version
    
    vergeSignpostEvent("Changes.init")
  }
  
  deinit {
    vergeSignpostEvent("Changes.deinit")
  }
  
  @inline(__always)
  private func cloneWithDropsPrevious() -> Changes<Value> {
    return .init(
      previous: nil,
      innerCurrent: innerCurrent,
      version: version
    )
  }
  
  public func asChanges() -> Changes<Value> {
    self
  }
  
  /// To create initial changes object
  public func droppedPrevious() -> Changes<Value> {
    cloneWithDropsPrevious()
  }
  
  @inlinable
  public subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
    _read {
      yield current[keyPath: keyPath]
    }
  }
  
  public typealias Selector<T> = KeyPath<Composing, T>
  
  /// Returns boolean that indicates value specified by keyPath contains changes with compared old and new.
  ///
  @inline(__always)
  public func noChanges<T: Equatable>(_ selector: Selector<T>) -> Bool {
    !hasChanges(selector, ==)
  }
  
  @inline(__always)
  public func noChanges<T>(_ selector: Selector<T>, _ compare: (T, T) -> Bool) -> Bool {
    
    !hasChanges(selector, compare)
  }
  
  @inline(__always)
  public func noChanges<T>(_ selector: Selector<T>, _ comparer: Comparer<T>) -> Bool {
    
    !hasChanges(selector, comparer.equals)
  }
    
  /// Returns boolean that indicates value specified by keyPath contains changes with compared old and new.
  ///
  @inline(__always)
  public func hasChanges<T: Equatable>(_ selector: Selector<T>) -> Bool {
    hasChanges(selector, ==)
  }
  
  @inline(__always)
  public func hasChanges<T>(_ selector: Selector<T>, _ comparer: Comparer<T>) -> Bool {
    hasChanges(selector, comparer.equals)
  }
  
  @inline(__always)
  public func hasChanges<Composed>(
    compose: (Composing) -> Composed,
    comparer: (Composed, Composed) -> Bool
  ) -> Bool {
    
    let signpost = VergeSignpostTransaction("Changes.hasChanges(compose:comparer:)")
    defer {
      signpost.end()
    }
    
    let current = Composing(source: self)
    
    guard let previousValue = previous else {
      return true
    }
    
    let old = Composing(source: previousValue)
        
    guard !comparer(compose(old), compose(current)) else {
      return false
    }
    
    return true
  }
  
  @inline(__always)
  public func hasChanges<T>(_ selector: Selector<T>, _ compare: (T, T) -> Bool) -> Bool {
    guard let old = previous else {
      return true
    }
    return !compare(Composing(source: old)[keyPath: selector], Composing(source: self)[keyPath: selector])
  }
    
  /// Do a closure if value specified by keyPath contains changes.
  @inline(__always)
  public func ifChanged<T: Equatable, Result>(_ keyPath: Selector<T>, _ perform: (T) throws -> Result) rethrows -> Result? {
    try ifChanged(keyPath, ==, perform)
  }
  
  /// Do a closure if value specified by keyPath contains changes.
  public func ifChanged<T, Result>(_ selector: Selector<T>, _ comparer: (T, T) -> Bool, _ perform: (T) throws -> Result) rethrows -> Result? {
    guard hasChanges(selector, comparer) else { return nil }
    return try perform(Composing(source: self)[keyPath: selector])
  }
  
  public func ifChanged<Composed, Result>(
    compose: (Composing) -> Composed,
    comparer: (Composed, Composed) -> Bool,
    perform: (Composed) throws -> Result
  ) rethrows -> Result? {
    
    let current = Composing(source: self)
    
    guard let previousValue = previous else {
      return try perform(compose(.init(source: self)))
    }
    
    let old = Composing(source: previousValue)
    
    let composedOld = compose(old)
    let composedNew = compose(current)
    
    guard !comparer(composedOld, composedNew) else {
      return nil
    }
    
    return try perform(composedNew)
  }
  
  public func map<U>(_ transform: (Value) throws -> U) rethrows -> Changes<U> {
    Changes<U>(
      previous: try previous.map { try $0.map(transform) },
      innerCurrent: try innerCurrent.map(transform),
      version: version
    )
  }
  
  public func makeNextChanges(with nextNewValue: Value) -> Changes<Value> {
    
    let previous = cloneWithDropsPrevious()
    let nextVersion = previous.version &+ 1
    return Changes<Value>.init(
      previous: previous,
      innerCurrent: .init(value: nextNewValue),
      version: nextVersion
    )
  }

}

// MARK: - Nested Types

extension Changes {
  
  private struct InnerCurrent {
    
    let value: Value
    
    let cachedComputedValueStorage: VergeConcurrency.Atomic<[AnyKeyPath : Any]>
    
    init(value: Value) {
      self.value = value
      self.cachedComputedValueStorage = .init([:])
    }
    
    private init(
      value: Value,
      cachedComputedValueStorage: VergeConcurrency.Atomic<[AnyKeyPath : Any]>
    ) {
      self.value = value
      self.cachedComputedValueStorage = cachedComputedValueStorage
    }
    
    public func map<U>(_ transform: (Value) throws -> U) rethrows -> Changes<U>.InnerCurrent {
      return .init(value: try transform(value), cachedComputedValueStorage: cachedComputedValueStorage)
    }
  }
  
}

extension Changes {
  
  @dynamicMemberLookup
  public struct Composing {
    
    private let source: Changes<Value>
    
    public var root: Value {
      source.current
    }
    
    fileprivate init(source: Changes<Value>) {
      self.source = source
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
      _read {
        yield source[dynamicMember: keyPath]
      }
    }
        
  }
}

extension Changes.Composing where Value : ExtendedStateType {
  public var computed: Changes.ComputedProxy {
    .init(source: source)
  }
}

extension Changes where Value : ExtendedStateType {
  
  @dynamicMemberLookup
  public struct ComputedProxy {
    let source: Changes<Value>
    
    public subscript<Output>(dynamicMember keyPath: KeyPath<Value.Extended, Value.Field.Computed<Output>>) -> Output {
      take(with: keyPath)
    }
    
    @inline(__always)
    private func take<Output>(with keyPath: KeyPath<Value.Extended, Value.Field.Computed<Output>>) -> Output {
      return source._synchronized_takeFromCacheOrCreate(keyPath: keyPath)
    }
  }
  
  public var computed: ComputedProxy {
    .init(source: self)
  }
        
  @inline(__always)
  private func _synchronized_takeFromCacheOrCreate<Output>(
    keyPath: KeyPath<Value.Extended, Value.Field.Computed<Output>>
  ) -> Output {

    let components = Value.Extended.instance[keyPath: keyPath]
    
    components._onRead()
    
    // TODO: tune-up concurrency performance
            
    return innerCurrent.cachedComputedValueStorage.modify { cache -> Output in
      
      if let computed = cache[keyPath] as? Output {
        components._onHitCache()
        // if cached, take value withoud shared lock
        return computed
      }
      
      if let previous = previous {
        
        return previous.innerCurrent.cachedComputedValueStorage.modify { previousCache -> Output in
          if let previousCachedValue = previousCache[keyPath] as? Output {
            
            components._onHitPreviousCache()
            
            switch components.memoizeMap.makeResult(self) {
            case .noChanages:
              
              // No changes
              components._onHitPreFilter()
              cache[keyPath] = previousCachedValue
              return previousCachedValue
              
            case .updated(let newValue):
              
              // Update
              components._onTransform()
              cache[keyPath] = newValue
              return newValue
            }
          } else {
            
            components._onTransform()
            
            let initialValue = components.memoizeMap.makeInitial(self)
            cache[keyPath] = initialValue
            return initialValue
            
          }
        }
        
      } else {
        
        components._onTransform()
        
        let initialValue = components.memoizeMap.makeInitial(self)
        cache[keyPath] = initialValue        
        return initialValue
      }
      
    }
                          
  }
  
}

extension Changes where Value : Equatable {
  
  public var hasChanges: Bool {
    old != current
  }
  
  public func ifChanged(_ perform: (Value) throws -> Void) rethrows {
    try ifChanged(\.root, perform)
  }
}


extension _StateTypeContainer {
        
  public struct Computed<Output> {
    
    public typealias Input = Changes<State>
    
    @usableFromInline
    fileprivate(set) var _onRead: () -> Void = {}
    
    @usableFromInline
    fileprivate(set) var _onHitCache: () -> Void = {}
    
    @usableFromInline
    fileprivate(set) var _onHitPreviousCache: () -> Void = {}
    
    @usableFromInline
    fileprivate(set) var _onHitPreFilter: () -> Void = {}
    
    @usableFromInline
    fileprivate(set) var _onTransform: () -> Void = {}
    
    @usableFromInline
    let memoizeMap: MemoizeMap<Input, Output>
    
    @usableFromInline
    init(_ filterMap: MemoizeMap<Input, Output>) {
      self.memoizeMap = filterMap
    }
    
    public init(
      makeInitial: @escaping (Input) -> Output,
      update: @escaping (Input) -> MemoizeMap<Input, Output>.Result
    ) {
      self.init(MemoizeMap<Input, Output>.init(makeInitial: makeInitial, update: update))
    }
        
    public init(_ compute: @escaping (Input) -> Output) {
      self.init(.init(map: compute))
    }
    
    @inlinable
    @inline(__always)
    public func dropsInput(while predicate: @escaping (Input) -> Bool) -> Self {
      modified {
        $0.dropsInput(while: predicate)
      }
    }
    
    @inlinable
    @inline(__always)
    public func modified(_ modifier: (MemoizeMap<Input, Output>) -> MemoizeMap<Input, Output>) -> Self {
      .init(modifier(memoizeMap))
    }
                       
    @inlinable
    @inline(__always)
    public func onRead(_ clsoure: @escaping () -> Void) -> Self {
      
      var _self = self
      _self._onRead = clsoure
      return _self
    }
    
    @inlinable
    @inline(__always)
    public func onTransform(_ closure: @escaping () -> Void) -> Self {
      
      var _self = self
      _self._onTransform = closure
      return _self
    }
    
    @inlinable
    @inline(__always)
    public func onHitPreFilter(_ closure: @escaping () -> Void) -> Self {
      
      var _self = self
      _self._onHitPreFilter = closure
      return _self
    }
    
    @inlinable
    @inline(__always)
    public func onHitCache(_ closure: @escaping () -> Void) -> Self {
      
      var _self = self
      _self._onHitCache = closure
      return _self
    }
    
    @inlinable
    @inline(__always)
    public func onHitPreviousCache(_ closure: @escaping () -> Void) -> Self {
      
      var _self = self
      _self._onHitPreviousCache = closure
      return _self
    }
    
  }
}
