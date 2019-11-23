//
//  PushData.swift
//  APNsClient
//
//  Created by muukii on 2019/11/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

struct PushData: Hashable {
  
  enum Enviroment: Int, Codable {
    case development = 0
    case production = 1
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
  var enviroment: PushData.Enviroment = .development
}
