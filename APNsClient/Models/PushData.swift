//
//  PushData.swift
//  APNsClient
//
//  Created by muukii on 2019/11/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import Backend

struct PushData: Hashable {
  
  enum Enviroment: Int, Codable {
    case sandbox = 0
    case production = 1
    
    var asAPN: APNEnvironment {
      switch self {
      case .sandbox: return .sandbox
      case .production: return .production
      }
    }
  }
  
  var bundleID: String
  var keyID: String
  var teamID: String
  var payload: String
  var deviceToken: String
  var enviroment: Enviroment
}

struct DraftPushData: Hashable, Codable {
   
  var bundleID: String = ""
  var keyID: String = ""
  var teamID: String = ""
  var payload: String = ""
  var deviceToken: String = ""
  var enviroment: PushData.Enviroment = .sandbox
}
