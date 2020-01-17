/*
Copyright 2019 Grabtaxi Holdings PTE LTE (GRAB), All rights reserved.
Use of this source code is governed by an MIT-style license that can be found in the LICENSE file
*/

import UIKit
import Alamofire
import ConfigService

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    let serviceVar = ServiceVariable()
    serviceVar.save()
    serviceVar.reload()
    serviceVar.reload2()
  }
}

