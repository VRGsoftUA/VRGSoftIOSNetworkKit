//
//  SMTestGateway.swift
//  VRGSoftIOSNetworkKit
//
//  Created by SEMENIUK OLEKSANDR on 16.03.2020.
//  Copyright © 2020 VRGSoft. All rights reserved.
//

import Alamofire

class SMTestGateway: SMGateway {

    static let shared: SMTestGateway = SMTestGateway()
    
    func getTestData() -> SMGatewayRequest {
        let req: SMGatewayRequest = request(type: .get, path: "json", parameters: nil) { _, _ -> SMResponse in
            
            return SMResponse()
        }
                
        return req
    }
}
