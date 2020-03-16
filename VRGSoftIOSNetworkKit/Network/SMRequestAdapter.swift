//
//  SMRequestAdapter.swift
//  VRGSoftIOSNetworkKit
//
//  Created by OLEKSANDR SEMENIUK on 7/17/18.
//  Copyright © 2020 VRG Soft. All rights reserved.
//

import Alamofire

open class SMRequestAdapter: RequestAdapter {

    public let request: SMGatewayRequest
    
    public init(request: SMGatewayRequest) {
        self.request = request
    }
    
    public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {        
        completion(.success(urlRequest))
    }
}
