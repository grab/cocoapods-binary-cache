//
//  UICommonsDynamicTests.swift
//  PrebuiltPodIntegrationTests
//
//  Created by Ngoc Thuyen Trinh on 09/10/2020.
//  Copyright © 2020 Grab. All rights reserved.
//

import XCTest
import UICommonsDynamic

final class UICommonsDynamicTests: XCTestCase {
  func testUICommonsDynamicTests() {
    XCTAssertNotNil(UICommonsDynamic.jsonString(from: "dynamic"))
  }
}
