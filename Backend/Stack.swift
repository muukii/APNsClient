//
//  Stack.swift
//  Service
//
//  Created by muukii on 2019/11/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public final class Stack {
  
  public let service: SessionService
  
  public init(sessionStateID: String) {
    
    self.service = SessionService(sessionStateID: sessionStateID)
  }
}
