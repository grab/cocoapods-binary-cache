/*
 Copyright 2020 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
 Use of this source code is governed by an MIT-style license that can be found in the LICENSE file
 */

import ConfigSDK

public final class ServiceVariable {
  private let raw: ConfigVar

  public init() {
    raw = ConfigVar()
  }

  public func reload() {
    raw.reload()
  }

  public func reload2() {
    raw.reload2()
  }

  public func save() {
    raw.saveToPersistent()
  }
}
