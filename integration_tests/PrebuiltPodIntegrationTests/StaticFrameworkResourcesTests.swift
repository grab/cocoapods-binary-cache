//
//  StaticFrameworkResourcesTests.swift
//  PrebuiltPodIntegrationTests
//
//  Created by Ngoc Thuyen Trinh on 11/05/2020.
//  Copyright © 2020 Grab. All rights reserved.
//

import XCTest
import BKMoneyKit

final class StaticFrameworkResourcesTests: XCTestCase {
  func testResourcesCopiedToMainBundle() {
    expectFiles(ofType: "png", inDir: "BKMoneyKit.bundle/CardLogo")
    expectFiles(ofType: "png", inDir: "GoogleMaps.bundle")
    expectFiles(ofType: "png", inDir: "GoogleSignIn.bundle")
    expectFiles(ofType: "png", inDir: "IQKeyboardManager.bundle")
  }

  private func expectFiles(
    ofType resourceType: String,
    inDir: String? = nil,
    _ file: StaticString = #file,
    _ line: UInt = #line
  ) {
    let paths = Bundle.main.paths(forResourcesOfType: resourceType, inDirectory: inDir)
    if paths.isEmpty {
      XCTFail("No resources of type \(resourceType) in dir: \(inDir ?? "nil")", file: file, line: line)
    }
  }
}
