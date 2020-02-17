/*
 Copyright 2020 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
 Use of this source code is governed by an MIT-style license that can be found in the LICENSE file
 */

/* This class is mainly to demonstrate ABI breaking.
 + Host: ConfigSDK this framework (can be static or dynamic linking)
 + Client: ConfigService that uses ConfigSDK (can be static or dynamic linking)
 If we prebuild ConfigService, then change ConfigSDK private stuffs (add variable, change variable from let to var,
 add new function) => the binary interface of ConfigSDK change => ConfigService stops working: crash, call worng funcs
 */

import Foundation

public protocol ConfigVarDelegate: AnyObject {
}

public class ConfigVar {

  // ⚠️ Try to change let -> var after prebuild can cause crash. when client call reload(). Because the memory layout is different.
  private let delegate: ConfigVarDelegate? = nil

  public init() {
    print("\(#function)")
  }

  // After prebuild, run again to see all functions are called as normal.
  // Then insert a new function here -> clean DerivedData -> run again to see magic happen

  // ⚠️ This function demonstrate ABI breaking when we add new function, variable on top of it.
  // + If we add new function -> client module (without recompiling) will wrongly call to new function
  // + If we change "let delegate" -> "var delegate" => cause crash when call this function
  // Note: remember to clean: rm -rf DerivedData after change, because Xcode will check that ExperimentService has no change (prebuilt) -> It don't rebuild ScribeSDK
  public func reload() {
    print("\(#function)")
  }

  // ⚠️ Has same issue with func above even with "dynamic" keyword (Xcode 10)
  public func reload2() {
    print("\(#function)")
  }
  
  // ✅ This function can be called correctly even when this class changes (add new ivar, func), and this Module's clients
  // don't need to recompile because it's lookup via objc-runtime
  @objc public dynamic func saveToPersistent() {
    print("\(#function)")
  }
}
