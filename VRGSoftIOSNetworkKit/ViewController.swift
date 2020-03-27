//
//  ViewController.swift
//  VRGSoftIOSNetworkKit
//
//  Created by SEMENIUK OLEKSANDR on 16.03.2020.
//  Copyright © 2020 VRGSoft. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        SMTestGateway.shared.getTestData().startWithResponseBlockInMainQueue { response in
            print(response)
        }
    }


}
