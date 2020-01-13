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

open class DispatcherBase<State, Activity>: DispatcherType {
        
  public typealias Context = DispatcherContext<DispatcherBase<State, Activity>>
  
  public let target: StoreBase<State, Activity>
  
  private var logger: VergeStoreLogger? {
    target.logger
  }
  
  public init(target store: StoreBase<State, Activity>) {
    self.target = store
    
    logger?.didCreateDispatcher(store: store, dispatcher: self)
  }
  
  deinit {
    logger?.didDestroyDispatcher(store: target, dispatcher: self)
  }
    
}

public protocol _VergeStore_OptionalProtocol {
  associatedtype Wrapped
  var _vergestore_wrappedValue: Wrapped? { get set }
}

extension Optional: _VergeStore_OptionalProtocol {
  
  public var _vergestore_wrappedValue: Wrapped? {
    get {
      return self
    }
    mutating set {
      self = newValue
    }
  }
}
